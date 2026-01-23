import 'package:equatable/equatable.dart';

class PlaylistProfile extends Equatable {
  final String id;
  final String name;
  final String url;
  final String? userId;
  final String? type; 
  final DateTime? lastUsed;
  // NUEVO CAMPO: Fecha de caducidad
  final DateTime? expirationDate; 

  const PlaylistProfile({
    required this.id,
    required this.name,
    required this.url,
    this.userId,
    this.type,
    this.lastUsed,
    this.expirationDate, // Añadido al constructor
  });

  @override
  List<Object?> get props => [id, name, url, userId, type, lastUsed, expirationDate];
}