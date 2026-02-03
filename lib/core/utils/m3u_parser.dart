import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';

class M3uParser {
  /// Parse M3U content into [Channel] list.
  ///
  /// Critical fix: channel IDs are **deterministic**.
  /// - If `tvg-id` exists, we use it.
  /// - Otherwise we create an MD5 of (name + url) so favorites stay stable after reload.
  static List<Channel> parse(String content) {
    final List<Channel> channels = [];
    final lines = content.split('\n');

    String? name;
    String? logoUrl;
    String? group;
    String? tvgId;
    String? tvgName;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.startsWith('#EXTINF:')) {
        // Parse basic metadata
        final attributes = line.substring(8);
        final parts = attributes.split(',');
        if (parts.length > 1) name = parts.last.trim();

        if (line.contains('tvg-logo="')) logoUrl = _extractAttribute(line, 'tvg-logo');
        if (line.contains('group-title="')) group = _extractAttribute(line, 'group-title');
        if (line.contains('tvg-id="')) tvgId = _extractAttribute(line, 'tvg-id');
        if (line.contains('tvg-name="')) tvgName = _extractAttribute(line, 'tvg-name');
      } else if (line.isNotEmpty && !line.startsWith('#')) {
        // Stream URL line
        if (name != null) {
          final id = _generateStableId(tvgId: tvgId, name: name!, url: line, tvgName: tvgName);
          channels.add(
            Channel(
              id: id,
              name: name!,
              url: line,
              logoUrl: logoUrl,
              group: group,
              tvgId: tvgId,
              tvgName: tvgName,
            ),
          );

          // Reset for next channel
          name = null;
          logoUrl = null;
          group = null;
          tvgId = null;
          tvgName = null;
        }
      }
    }

    return channels;
  }

  static String _generateStableId({
    required String? tvgId,
    required String name,
    required String url,
    required String? tvgName,
  }) {
    final canonicalTvgId = (tvgId ?? '').trim();
    if (canonicalTvgId.isNotEmpty) return canonicalTvgId;

    // Some providers use tvg-name as stable identifier.
    final base = '${(tvgName ?? name).trim()}|${url.trim()}';
    return md5.convert(utf8.encode(base)).toString();
  }

  static String? _extractAttribute(String line, String key) {
    final pattern = '$key="';
    final startIndex = line.indexOf(pattern);
    if (startIndex == -1) return null;
    final start = startIndex + pattern.length;
    final end = line.indexOf('"', start);
    if (end == -1) return null;
    return line.substring(start, end);
  }
}
