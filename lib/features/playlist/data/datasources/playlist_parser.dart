import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';

class PlaylistParser {
  List<Channel> parse(String m3uContent) {
    final channels = <Channel>[];
    final lines = m3uContent.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('#EXTINF:')) {
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

    return channels;
  }

  Map<String, String> _parseAttributes(String line) {
    final attributes = <String, String>{};
    final parts = line.split(' ');

    for (final part in parts) {
      if (part.contains('=')) {
        final keyValue = part.split('=');
        final key = keyValue[0];
        final value = keyValue[1].replaceAll('"', '');
        attributes[key] = value;
      }
    }

    // Extract title
    final titleMatch = RegExp(r',(.+)').firstMatch(line);
    if (titleMatch != null) {
      attributes['title'] = titleMatch.group(1)!;
    }

    return attributes;
  }
}
