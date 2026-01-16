import 'package:uuid/uuid.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';

class M3uParser {
  // Método ESTÁTICO (static)
  static List<Channel> parse(String content) {
    final List<Channel> channels = [];
    final lines = content.split('\n');
    String? name;
    String? logoUrl;
    String? group;
    String? tvgId;
    String? tvgName;

    for (var i = 0; i < lines.length; i++) {
      String line = lines[i].trim();

      if (line.startsWith('#EXTINF:')) {
        // Parsear metadatos básicos
        final attributes = line.substring(8);
        final parts = attributes.split(',');

        if (parts.length > 1) {
          name = parts.last.trim();
        }

        if (line.contains('tvg-logo="'))
          logoUrl = _extractAttribute(line, 'tvg-logo');
        if (line.contains('group-title="'))
          group = _extractAttribute(line, 'group-title');
        if (line.contains('tvg-id="'))
          tvgId = _extractAttribute(line, 'tvg-id');
        if (line.contains('tvg-name="'))
          tvgName = _extractAttribute(line, 'tvg-name');
      } else if (line.isNotEmpty && !line.startsWith('#')) {
        if (name != null) {
          channels.add(Channel(
            id: const Uuid().v4(),
            name: name,
            url: line,
            logoUrl: logoUrl,
            group: group,
            tvgId: tvgId,
            tvgName: tvgName,
          ));
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
