import 'dart:async';
import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:isolate';

import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:xml/xml.dart' as xml;

import 'package:omnistream_iptv/core/utils/app_logger.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';
import 'package:omnistream_iptv/core/epg/epg_models.dart';
import 'package:omnistream_iptv/core/epg/epg_settings_store.dart';
import 'package:omnistream_iptv/core/epg/epg_url_resolver.dart';
import 'package:omnistream_iptv/core/epg/epg_country_catalog.dart';

class EpgService {
  static const _metaKey = 'meta';
  static const _metaBoxName = 'epg_meta_v1';
  static const _nowNextBoxName = 'epg_now_next_v1';
  static const _nameIndexBoxName = 'epg_name_index_v1';
  static const _windowBoxName = 'epg_window_14h_v1';
  static const _windowMetaKey = 'window_meta';

  final http.Client client;
  final EpgSettingsStore settingsStore;

  final AppLogger _log = AppLogger('epg');

  Box<String>? _metaBox;
  Box<String>? _nowNextBox;
  Box<String>? _nameIndexBox;
  Box<String>? _windowBox;

  Map<String, EpgNowNext>? _cacheNowNextByXmltvId;
  Map<String, String>? _cacheNameToXmltvId;
  final Map<String, List<EpgProgram>> _memWindowCache = <String, List<EpgProgram>>{};

  EpgService({
    required this.client,
    required this.settingsStore,
  });

  Future<void> _ensureBoxes() async {
    _metaBox ??= await Hive.openBox<String>(_metaBoxName);
    _nowNextBox ??= await Hive.openBox<String>(_nowNextBoxName);
    _nameIndexBox ??= await Hive.openBox<String>(_nameIndexBoxName);
    _windowBox ??= await Hive.openBox<String>(_windowBoxName);
  }

  /// The effective source URL used for EPG at this moment.
  Uri resolveEffectiveUrl({String? playlistUrl}) {
    final s = settingsStore.load();

    if (s.mode == EpgMode.override) {
      final o = (s.overrideUrl ?? '').trim();
      if (o.isNotEmpty) return Uri.parse(o);
    }

    final derived = (playlistUrl == null) ? null : EpgUrlResolver.deriveXtreamXmltv(playlistUrl);
    if (derived != null) return derived;

    return EpgCountryCatalog.buildUri(
      countryCode: s.fallbackCountry,
      preferGzip: s.preferGzip,
    );
  }

  bool _isFresh(Map<String, dynamic> meta, EpgSettings s, Uri effectiveUrl) {
    final src = (meta['sourceUrl'] ?? '').toString();
    if (src != effectiveUrl.toString()) return false;
    final fetchedAtIso = (meta['fetchedAt'] ?? '').toString();
    if (fetchedAtIso.isEmpty) return false;

    final fetchedAt = DateTime.tryParse(fetchedAtIso);
    if (fetchedAt == null) return false;

    final age = DateTime.now().difference(fetchedAt);
    return age.inHours < s.refreshHours;
  }

  Future<Map<String, dynamic>> _readMeta() async {
    await _ensureBoxes();
    final raw = _metaBox!.get(_metaKey);
    if (raw == null || raw.trim().isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeMeta(Map<String, dynamic> meta) async {
    await _ensureBoxes();
    await _metaBox!.put(_metaKey, jsonEncode(meta));
  }

  /// Ensures EPG cache is present and (optionally) fresh.
  ///
  /// This method is safe to call repeatedly; it will avoid heavy work if the
  /// cache is still fresh.
  Future<void> ensureFresh({
    String? playlistUrl,
    bool force = false,
  }) async {
    await _ensureBoxes();

    final s = settingsStore.load();
    final url = resolveEffectiveUrl(playlistUrl: playlistUrl);

    final meta = await _readMeta();
    final fresh = _isFresh(meta, s, url);

    if (!force && fresh) {
      // Load in-memory caches from Hive for fast UI lookups.
      await _hydrateCachesFromHive();
      return;
    }

    _log.i('Refreshing EPG… (${url.toString()})');

    final xmlText = await _downloadXmltv(url);

    final nowIsoUtc = DateTime.now().toUtc().toIso8601String();

    final parsed = await Isolate.run(() => _parseXmltvIsolate(xmlText, nowIsoUtc));

    // Persist.
    final batchNow = <String, String>{};
    for (final entry in parsed.nowNextByChannelId.entries) {
      batchNow[entry.key] = jsonEncode(entry.value);
    }

    final batchIndex = <String, String>{};
    for (final entry in parsed.nameIndex.entries) {
      batchIndex[entry.key] = entry.value;
    }

    await _nowNextBox!.clear();
    await _nowNextBox!.putAll(batchNow);

    await _nameIndexBox!.clear();
    await _nameIndexBox!.putAll(batchIndex);

    // Persist 14h window (NOW-2h → NOW+12h) per channel.
    final batchWindow = <String, String>{};
    for (final entry in parsed.windowByChannelId.entries) {
      batchWindow[entry.key] = jsonEncode(entry.value);
    }
    await _windowBox!.clear();
    await _windowBox!.putAll(batchWindow);
    await _windowBox!.put(
      _windowMetaKey,
      jsonEncode({
        'windowStartUtc': parsed.windowStartUtc,
        'windowEndUtc': parsed.windowEndUtc,
      }),
    );

    final newMeta = <String, dynamic>{
      'sourceUrl': url.toString(),
      'fetchedAt': DateTime.now().toIso8601String(),
      'channelCount': parsed.channelCount,
      'programCount': parsed.programCount,
    };
    await _writeMeta(newMeta);

    await _hydrateCachesFromHive();
    _memWindowCache.clear();
    _log.i('EPG ready: channels=${parsed.channelCount} programs=${parsed.programCount}');
  }

  Future<void> _hydrateCachesFromHive() async {
    await _ensureBoxes();

    // Build NowNext map.
    final nowMap = <String, EpgNowNext>{};
    for (final key in _nowNextBox!.keys) {
      final k = key.toString();
      final raw = _nowNextBox!.get(k);
      if (raw == null) continue;
      try {
        final obj = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        nowMap[k] = EpgNowNext.fromJson(obj);
      } catch (_) {}
    }

    final indexMap = <String, String>{};
    for (final key in _nameIndexBox!.keys) {
      final k = key.toString();
      final v = _nameIndexBox!.get(k);
      if (v == null) continue;
      indexMap[k] = v;
    }

    _cacheNowNextByXmltvId = nowMap;
    _cacheNameToXmltvId = indexMap;
  }

  /// Returns the cached 14h window for a channel (NOW-2h → NOW+12h).
  ///
  /// Requires [ensureFresh] at least once in the session.
  Future<List<EpgProgram>> lookupWindow(Channel channel) async {
    await _ensureBoxes();
    if (_cacheNameToXmltvId == null || _cacheNowNextByXmltvId == null) {
      // In case caller didn't go through ensureFresh path.
      await _hydrateCachesFromHive();
    }

    final xmltvId = _resolveXmltvChannelId(channel);
    if (xmltvId == null) return const <EpgProgram>[];

    final cached = _memWindowCache[xmltvId];
    if (cached != null) return cached;

    final raw = _windowBox!.get(xmltvId);
    if (raw == null || raw.trim().isEmpty) return const <EpgProgram>[];

    try {
      final list = (jsonDecode(raw) as List).cast<Map>();
      final out = list
          .map((e) => EpgProgram.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      // Small LRU-ish cap.
      if (_memWindowCache.length > 60) _memWindowCache.clear();
      _memWindowCache[xmltvId] = out;
      return out;
    } catch (_) {
      return const <EpgProgram>[];
    }
  }

  /// Returns the current window range (UTC) for the timeline.
  Future<(DateTime, DateTime)?> windowRangeUtc() async {
    await _ensureBoxes();
    final raw = _windowBox!.get(_windowMetaKey);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final obj = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final a = DateTime.parse(obj['windowStartUtc'] as String);
      final b = DateTime.parse(obj['windowEndUtc'] as String);
      return (a, b);
    } catch (_) {
      return null;
    }
  }

  String? _resolveXmltvChannelId(Channel channel) {
    final tvgId = (channel.tvgId ?? '').trim();
    if (tvgId.isNotEmpty) return tvgId;

    final index = _cacheNameToXmltvId ?? const <String, String>{};
    final nameCandidates = <String>[
      (channel.tvgName ?? '').trim(),
      channel.name.trim(),
    ].where((s) => s.isNotEmpty).toList();

    for (final n in nameCandidates) {
      final key = _normalize(n);
      final xmltvId = index[key];
      if (xmltvId != null) return xmltvId;
    }
    return null;
  }

  /// Fast lookup (in-memory). Call [ensureFresh] first.
  EpgNowNext? lookupNowNext(Channel channel) {
    final map = _cacheNowNextByXmltvId;
    if (map == null || map.isEmpty) return null;

    final tvgId = (channel.tvgId ?? '').trim();
    if (tvgId.isNotEmpty) {
      final direct = map[tvgId];
      if (direct != null) return direct;
    }

    final index = _cacheNameToXmltvId ?? {};
    final nameCandidates = <String>[
      (channel.tvgName ?? '').trim(),
      channel.name.trim(),
    ].where((s) => s.isNotEmpty).toList();

    for (final n in nameCandidates) {
      final key = _normalize(n);
      final xmltvId = index[key];
      if (xmltvId != null) {
        final hit = map[xmltvId];
        if (hit != null) return hit;
      }
    }

    return null;
  }

  /// Returns the effective URL and the latest meta (useful for UI).
  Future<(Uri, Map<String, dynamic>)> info({String? playlistUrl}) async {
    final url = resolveEffectiveUrl(playlistUrl: playlistUrl);
    final meta = await _readMeta();
    return (url, meta);
  }

  Future<String> _downloadXmltv(Uri url) async {
    final res = await client
        .get(
          url,
          headers: const {
            'User-Agent': 'VIVID IPTV',
            'Accept': '*/*',
          },
        )
        .timeout(const Duration(seconds: 25));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('EPG download failed: HTTP ${res.statusCode}');
    }

    List<int> bytes = res.bodyBytes;

    // Detect gzip by magic header (1F 8B).
    if (bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
      bytes = gzip.decode(bytes);
    }

    return utf8.decode(bytes, allowMalformed: true);
  }
}

class _EpgParseResult {
  final Map<String, Map<String, dynamic>> nowNextByChannelId;
  final Map<String, String> nameIndex;
  final Map<String, List<Map<String, dynamic>>> windowByChannelId;
  final String windowStartUtc;
  final String windowEndUtc;
  final int channelCount;
  final int programCount;

  const _EpgParseResult({
    required this.nowNextByChannelId,
    required this.nameIndex,
    required this.windowByChannelId,
    required this.windowStartUtc,
    required this.windowEndUtc,
    required this.channelCount,
    required this.programCount,
  });
}

/// Isolate entrypoint.
/// Returns serializable maps (avoid sending custom objects across isolates).
_EpgParseResult _parseXmltvIsolate(String xmlText, String nowIsoUtc) {
  final now = DateTime.parse(nowIsoUtc).toUtc();
  final windowStart = now.subtract(const Duration(hours: 2));
  final windowEnd = now.add(const Duration(hours: 12));

  // Parse document.
  final doc = xml.XmlDocument.parse(xmlText);

  // 1) Build channel display-name index.
  final channels = doc.findAllElements('channel');
  final nameIndex = <String, String>{}; // normalizedName -> xmltvChannelId
  int channelCount = 0;

  for (final ch in channels) {
    final id = ch.getAttribute('id');
    if (id == null || id.trim().isEmpty) continue;
    channelCount++;

    for (final dn in ch.findElements('display-name')) {
      final text = dn.innerText.trim();
      if (text.isEmpty) continue;
      final key = _normalize(text);
      nameIndex.putIfAbsent(key, () => id);
    }
  }

  // 2) Scan programmes and compute now/next per channel.
  final nowMap = <String, Map<String, dynamic>>{};
  final nextMap = <String, Map<String, dynamic>>{};
  final windowMap = <String, List<Map<String, dynamic>>>{};
  int programCount = 0;

  for (final p in doc.findAllElements('programme')) {
    programCount++;

    final channelId = (p.getAttribute('channel') ?? '').trim();
    if (channelId.isEmpty) continue;

    final startRaw = p.getAttribute('start');
    final stopRaw = p.getAttribute('stop');
    if (startRaw == null || stopRaw == null) continue;

    final start = _parseXmltvTimeToUtc(startRaw);
    final stop = _parseXmltvTimeToUtc(stopRaw);
    if (start == null || stop == null) continue;
    if (!stop.isAfter(start)) continue;

    final titleEl = p.getElement('title');
    final title = (titleEl?.innerText ?? '').trim();
    if (title.isEmpty) continue;

    final descEl = p.getElement('desc');
    final desc = (descEl?.innerText ?? '').trim();
    final descOrNull = desc.isEmpty ? null : desc;

    final prog = <String, dynamic>{
      'title': title,
      'start': start.toIso8601String(),
      'stop': stop.toIso8601String(),
      'description': descOrNull,
    };

    // Add to 14h window if overlaps.
    if (stop.isAfter(windowStart) && start.isBefore(windowEnd)) {
      final list = windowMap.putIfAbsent(channelId, () => <Map<String, dynamic>>[]);
      list.add(prog);
    }

    if (!start.isAfter(now) && stop.isAfter(now)) {
      final existing = nowMap[channelId];
      if (existing == null) {
        nowMap[channelId] = prog;
      } else {
        // Keep latest start.
        final exStart = DateTime.parse(existing['start'] as String);
        if (start.isAfter(exStart)) nowMap[channelId] = prog;
      }
    } else if (start.isAfter(now)) {
      final existing = nextMap[channelId];
      if (existing == null) {
        nextMap[channelId] = prog;
      } else {
        // Keep earliest next.
        final exStart = DateTime.parse(existing['start'] as String);
        if (start.isBefore(exStart)) nextMap[channelId] = prog;
      }
    }
  }

  // 2.5) Sort windows by start time (and keep them compact).
  for (final entry in windowMap.entries) {
    entry.value.sort((a, b) {
      final sa = DateTime.parse(a['start'] as String);
      final sb = DateTime.parse(b['start'] as String);
      return sa.compareTo(sb);
    });
    // Safety cap per channel to avoid absurd payloads.
    if (entry.value.length > 120) {
      entry.value.removeRange(120, entry.value.length);
    }
  }

  // 3) Compose EpgNowNext JSON per channel.
  final out = <String, Map<String, dynamic>>{};
  final ids = <String>{...nowMap.keys, ...nextMap.keys};

  for (final id in ids) {
    out[id] = <String, dynamic>{
      'channelId': id,
      'now': nowMap[id],
      'next': nextMap[id],
    };
  }

  return _EpgParseResult(
    nowNextByChannelId: out,
    nameIndex: nameIndex,
    windowByChannelId: windowMap,
    windowStartUtc: windowStart.toIso8601String(),
    windowEndUtc: windowEnd.toIso8601String(),
    channelCount: channelCount,
    programCount: programCount,
  );
}

/// Parse XMLTV datetime string and convert to UTC.
/// Typical formats:
/// - 20250131123000 +0100
/// - 20250131123000+0100
/// - 20250131123000Z
DateTime? _parseXmltvTimeToUtc(String raw) {
  final s = raw.trim();
  if (s.length < 14) return null;

  final main = s.substring(0, 14);
  final year = int.tryParse(main.substring(0, 4));
  final mon = int.tryParse(main.substring(4, 6));
  final day = int.tryParse(main.substring(6, 8));
  final hour = int.tryParse(main.substring(8, 10));
  final min = int.tryParse(main.substring(10, 12));
  final sec = int.tryParse(main.substring(12, 14));
  if ([year, mon, day, hour, min, sec].any((v) => v == null)) return null;

  // Default: treat as UTC if no offset.
  var dt = DateTime.utc(year!, mon!, day!, hour!, min!, sec!);

  // Offset parsing.
  final rest = s.substring(14).trim();
  if (rest.isEmpty) return dt;

  if (rest == 'Z' || rest == 'z') return dt;

  // Supports "+0100", "+01:00", with optional leading space.
  final m = RegExp(r'^([+-])(\d{2}):?(\d{2})').firstMatch(rest);
  if (m == null) return dt;

  final sign = m.group(1) == '-' ? -1 : 1;
  final oh = int.tryParse(m.group(2) ?? '0') ?? 0;
  final om = int.tryParse(m.group(3) ?? '0') ?? 0;

  final offset = Duration(hours: oh, minutes: om) * sign;
  // Local time = UTC + offset -> UTC = local - offset.
  dt = dt.subtract(offset);
  return dt;
}

String _normalize(String input) {
  var s = input.toLowerCase().trim();

  // Strip diacritics (basic Latin).
  const map = {
    'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a',
    'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
    'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
    'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
    'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
    'ñ': 'n', 'ç': 'c',
  };
  map.forEach((k, v) {
    s = s.replaceAll(k, v);
  });

  // Remove common quality tags.
  s = s.replaceAll(RegExp(r'\b(uhd|fhd|hd|sd|4k)\b'), '');

  // Replace non-alphanumeric by space.
  s = s.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

  return s;
}
