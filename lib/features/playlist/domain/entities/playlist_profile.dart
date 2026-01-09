import 'package:equatable/equatable.dart';

class PlaylistProfile extends Equatable {
  final String id;
  final String name;
  final String url;
  // Añadimos este campo que faltaba para coincidir con el modelo
  final String? userId; 

  const PlaylistProfile({
    required this.id,
    required this.name,
    required this.url,
    this.userId, // Añadido al constructor
  });

  @override
  List<Object?> get props => [id, name, url, userId];
}