part of 'playlist_profile_bloc.dart';

abstract class PlaylistProfileState extends Equatable {
  const PlaylistProfileState();

  @override
  List<Object> get props => [];
}

class PlaylistProfileInitial extends PlaylistProfileState {}

class PlaylistProfileLoading extends PlaylistProfileState {}

// PLURAL: Para que coincida con lo que espera la página
class PlaylistProfilesLoaded extends PlaylistProfileState {
  final List<PlaylistProfile> profiles;

  const PlaylistProfilesLoaded({required this.profiles});

  @override
  List<Object> get props => [profiles];
}

class PlaylistProfileError extends PlaylistProfileState {
  final String message;

  const PlaylistProfileError({required this.message});

  @override
  List<Object> get props => [message];
}