import 'package:equatable/equatable.dart';

import '../../domain/entities/channel.dart';

abstract class PlaylistEvent extends Equatable {
  const PlaylistEvent();

  @override
  List<Object?> get props => [];
}

/// Carga la playlist desde una URL (M3U, etc.)
class LoadPlaylist extends PlaylistEvent {
  final String url;

  const LoadPlaylist({required this.url});

  @override
  List<Object?> get props => [url];
}

/// Filtra canales por texto (nombre o grupo).
class FilterChannels extends PlaylistEvent {
  final String query;

  const FilterChannels(this.query);

  @override
  List<Object?> get props => [query];
}

/// Limpia el filtro.
class ClearFilter extends PlaylistEvent {
  const ClearFilter();
}

/// Marca / desmarca canal como favorito.
class ToggleFavoriteChannel extends PlaylistEvent {
  final Channel channel;

  const ToggleFavoriteChannel(this.channel);

  @override
  List<Object?> get props => [channel];
}
