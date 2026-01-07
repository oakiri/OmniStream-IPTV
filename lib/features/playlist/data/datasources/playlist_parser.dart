import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';

class PlaylistParser {
  Future<List<Channel>> parse(String m3uContent) async {
    return compute(_parseM3uInIsolate, m3uContent);
  }

  static List<Channel> _parseM3uInIsolate(String m3uContent) {
    final channels = <Channel>[];
    final lines = m3uContent.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('#EXTINF:')) {
        // Check if there is a next line for the URL
        if (i + 1 < lines.length) {
          final url = lines[++i].trim();
          final attributes = _parseAttributes(line);
          channels.add(
            Channel(
              id: attributes['tvg-id'] ?? '',
              name: attributes['title'] ?? '',
              logoUrl: attributes['tvg-logo'],
              url: url,
              group: attributes['group-title'],
            ),
          );
        }
      }
    }

    return channels;
  }

  static Map<String, String> _parseAttributes(String line) {
    final attributes = <String, String>{};
    final parts = line.split(' ');

    for (final part in parts) {
      if (part.contains('=')) {
        final keyValue = part.split('=');
        final key = keyValue[0];
        // Remove quotes from value
        final value = keyValue[1].replaceAll('"', '');
        attributes[key] = value;
      }
    }

    // Extract title
    final titleMatch = RegExp(r',(.+)').firstMatch(line);
    if (titleMatch != null) {
      // Remove leading space and trim
      attributes['title'] = titleMatch.group(1)!.trim();
    }

    return attributes;
  }
}
