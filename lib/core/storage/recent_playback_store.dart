import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';
import 'package:omnistream_iptv/core/utils/app_logger.dart';

/// Persiste el último canal reproducido para el bloque "Continuar viendo".
///
/// Diseñado para UX premium:
/// - Guarda lo mínimo para reanudar (canal + url).
/// - Si [playlistUrl] está disponible, habilita "Ir a lista".
class RecentPlaybackStore {
  static const _log = AppLogger('playback.recent');

  RecentPlaybackStore({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  static const String _kLastChannelKey = 'recent_last_channel_v1';

  Future<void> saveLastChannel({required Channel channel, String? playlistUrl}) async {
    final data = RecentChannelPlayback(
      playlistUrl: (playlistUrl ?? '').trim(),
      channelId: channel.id,
      channelName: channel.name,
      channelUrl: channel.url,
      logoUrl: channel.logoUrl,
      group: channel.group ?? channel.groupTitle,
      lastSeenAtMillis: DateTime.now().millisecondsSinceEpoch,
    );
    await _prefs.setString(_kLastChannelKey, jsonEncode(data.toJson()));
    _log.ui('Saved last channel: ${channel.name}');
  }

  Future<RecentChannelPlayback?> loadLastChannel() async {
    final raw = _prefs.getString(_kLastChannelKey);
    if (raw == null || raw.trim().isEmpty) {
      _log.ui('No last channel stored');
      return null;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final loaded = RecentChannelPlayback.fromJson(map);
      _log.ui('Loaded last channel: ${loaded.channelName}');
      return loaded;
    } catch (_) {
      // Si el JSON se corrompe, lo limpiamos para evitar loops.
      await _prefs.remove(_kLastChannelKey);
      _log.warn('Last channel JSON corrupt -> cleared');
      return null;
    }
  }

  Future<void> clearLastChannel() async {
    await _prefs.remove(_kLastChannelKey);
    _log.ui('Cleared last channel');
  }
}

class RecentChannelPlayback {
  final String playlistUrl;
  final String channelId;
  final String channelName;
  final String channelUrl;
  final String? logoUrl;
  final String? group;
  final int lastSeenAtMillis;

  const RecentChannelPlayback({
    required this.playlistUrl,
    required this.channelId,
    required this.channelName,
    required this.channelUrl,
    required this.logoUrl,
    required this.group,
    required this.lastSeenAtMillis,
  });

  DateTime get lastSeenAt => DateTime.fromMillisecondsSinceEpoch(lastSeenAtMillis);

  Channel toChannel() {
    return Channel(
      id: channelId,
      name: channelName,
      logoUrl: logoUrl,
      url: channelUrl,
      group: group,
    );
  }

  Map<String, dynamic> toJson() => {
        'playlistUrl': playlistUrl,
        'channelId': channelId,
        'channelName': channelName,
        'channelUrl': channelUrl,
        'logoUrl': logoUrl,
        'group': group,
        'lastSeenAtMillis': lastSeenAtMillis,
      };

  static RecentChannelPlayback fromJson(Map<String, dynamic> json) {
    return RecentChannelPlayback(
      playlistUrl: (json['playlistUrl'] as String? ?? '').trim(),
      channelId: json['channelId'] as String? ?? '',
      channelName: json['channelName'] as String? ?? '',
      channelUrl: json['channelUrl'] as String? ?? '',
      logoUrl: json['logoUrl'] as String?,
      group: json['group'] as String?,
      lastSeenAtMillis: (json['lastSeenAtMillis'] as num?)?.toInt() ?? 0,
    );
  }
}
