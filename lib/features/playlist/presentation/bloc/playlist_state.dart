part of 'playlist_bloc.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/category.dart' as entity;

abstract class PlaylistState extends Equatable {
  const PlaylistState();

  @override
  List<Object> get props => [];
}

class PlaylistInitial extends PlaylistState {}

class PlaylistLoading extends PlaylistState {}

class PlaylistLoaded extends PlaylistState {
  final List<Channel> channels;
  final List<entity.Category> categories;

  const PlaylistLoaded({required this.channels, required this.categories});

  @override
  List<Object> get props => [channels, categories];
}

class PlaylistError extends PlaylistState {
  final String message;

  const PlaylistError(this.message);

  @override
  List<Object> get props => [message];
}
