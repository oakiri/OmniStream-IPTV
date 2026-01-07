part of 'playlist_profile_bloc.dart';

abstract class PlaylistProfileEvent extends Equatable {
  const PlaylistProfileEvent();

  @override
  List<Object> get props => [];
}

class LoadPlaylistProfiles extends PlaylistProfileEvent {}

class AddProfileEvent extends PlaylistProfileEvent {
  final PlaylistProfile profile;

  const AddProfileEvent(this.profile);

  @override
  List<Object> get props => [profile];
}

class DeleteProfileEvent extends PlaylistProfileEvent {
  final String id;

  const DeleteProfileEvent(this.id);

  @override
  List<Object> get props => [id];
}