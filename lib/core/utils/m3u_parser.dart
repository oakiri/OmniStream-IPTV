import 'package:omnistream_iptv/features/channels/domain/entities/channel.dart';

class M3UParser {
  static Future<List<Channel>> parse(String m3uContent) async {
    final List<Channel> channels = [];
    final lines = m3uContent.split('\n');

    for (var i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('#EXTINF')) {
        final infoLine = lines[i];
        final urlLine = (i + 1 < lines.length) ? lines[i + 1].trim() : '';

        if (urlLine.isNotEmpty && urlLine.startsWith('http')) {
          final id = _extractAttribute(infoLine, 'tvg-id');
          final name = infoLine.split(',').last.trim();
          final logoUrl = _extractAttribute(infoLine, 'tvg-logo');
          final group = _extractAttribute(infoLine, 'group-title');

          channels.add(Channel(
            id: id ?? name, // Use name as fallback for id
            name: name,
            url: urlLine,
            logoUrl: logoUrl,
            group: group,
          ));
        }
      }
    }
    return channels;
  }

  static String? _extractAttribute(String line, String attribute) {
    final regex = RegExp('$attribute="(.*?)"');
    final match = regex.firstMatch(line);
    return match?.group(1);
  }
}
