import 'package:equatable/equatable.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';

abstract class PlaylistEvent extends Equatable {
  const PlaylistEvent();

  @override
  List<Object?> get props => [];
}

class LoadPlaylist extends PlaylistEvent {
  final String url;
  const LoadPlaylist(this.url);

  @override
  List<Object?> get props => [url];
}

class ToggleFavoriteChannel extends PlaylistEvent {
  final Channel channel;
  const ToggleFavoriteChannel(this.channel);

  @override
  List<Object?> get props => [channel];
}