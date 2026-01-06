part of 'playlist_bloc.dart';

abstract class PlaylistEvent extends Equatable {
  const PlaylistEvent();

  @override
  List<Object> get props => [];
}

class LoadPlaylist extends PlaylistEvent {
  final String url;

  const LoadPlaylist(this.url);

  @override
  List<Object> get props => [url];
}
