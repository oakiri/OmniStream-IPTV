part of 'playlist_profile_bloc.dart';

abstract class PlaylistProfileEvent extends Equatable {
  const PlaylistProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadPlaylistProfiles extends PlaylistProfileEvent {}

// ESTE ES EL EVENTO CLAVE QUE DEBE COINCIDIR CON EL DIALOG
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

class DeleteProfileEvent extends PlaylistProfileEvent {
  final String id;

  const DeleteProfileEvent(this.id);

  @override
  List<Object> get props => [id];
}