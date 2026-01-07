import 'package:equatable/equatable.dart';

class PlaylistProfile extends Equatable {
  final String id;
  final String name;
  final String url;
  final DateTime lastUpdated;
  final bool isFavorite;
  final String? userId;

  const PlaylistProfile({
    required this.id,
    required this.name,
    required this.url,
    required this.lastUpdated,
    required this.isFavorite,
    this.userId,
  });

  @override
  List<Object?> get props => [id, name, url, lastUpdated, isFavorite, userId];
}
