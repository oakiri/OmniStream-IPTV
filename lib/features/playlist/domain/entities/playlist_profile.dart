import 'package:equatable/equatable.dart';

class PlaylistProfile extends Equatable {
  final String id;
  final String name;
  final String url;
  final String? type; // m3u, xtream, etc (opcional)
  final DateTime? lastUsed;

  const PlaylistProfile({
    required this.id,
    required this.name,
    required this.url,
    this.type,
    this.lastUsed,
  });

  @override
  List<Object?> get props => [id, name, url, type, lastUsed];
}
