import 'package:equatable/equatable.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/playlist_profile.dart';

abstract class PlaylistProfileState extends Equatable {
  const PlaylistProfileState();

  @override
  List<Object> get props => [];
}

class PlaylistProfileInitial extends PlaylistProfileState {}

class PlaylistProfileLoading extends PlaylistProfileState {}

class PlaylistProfileLoaded extends PlaylistProfileState {
  final List<PlaylistProfile> profiles;

  const PlaylistProfileLoaded({required this.profiles});

  @override
  List<Object> get props => [profiles];
}

class PlaylistProfileError extends PlaylistProfileState {
  final String message;

  const PlaylistProfileError({required this.message});

  @override
  List<Object> get props => [message];
}
