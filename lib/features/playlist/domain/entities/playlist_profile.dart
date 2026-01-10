import 'package:equatable/equatable.dart';

class PlaylistProfile extends Equatable {
  final String id;
  final String name;
  final String url;
  final String? userId;
  // Añadimos los campos que faltaban y que AddPlaylistDialog está pidiendo
  final String? type; 
  final DateTime? lastUsed;

  const PlaylistProfile({
    required this.id,
    required this.name,
    required this.url,
    this.userId,
    this.type,
    this.lastUsed,
  });

  @override
  List<Object?> get props => [id, name, url, userId, type, lastUsed];
}