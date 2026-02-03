part of 'playlist_profile_bloc.dart';

abstract class PlaylistProfileEvent extends Equatable {
  const PlaylistProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadPlaylistProfiles extends PlaylistProfileEvent {}

// Evento corregido para aceptar datos individuales desde el formulario
class AddProfileEvent extends PlaylistProfileEvent {
  final String name;
  final String url;
  final String? username;
  final String? password;

  const AddProfileEvent({
    required this.name,
    required this.url,
    this.username,
    this.password,
  });

  @override
  List<Object?> get props => [name, url, username, password];
}

class UpdateProfileEvent extends PlaylistProfileEvent {
  final PlaylistProfile existing;
  final String name;
  final String url;
  final String? username;
  final String? password;

  const UpdateProfileEvent({
    required this.existing,
    required this.name,
    required this.url,
    this.username,
    this.password,
  });

  @override
  List<Object?> get props => [existing, name, url, username, password];
}

class DeleteProfileEvent extends PlaylistProfileEvent {
  final String id;

  const DeleteProfileEvent(this.id);

  @override
  List<Object> get props => [id];
}