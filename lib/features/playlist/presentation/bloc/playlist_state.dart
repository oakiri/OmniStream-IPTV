import 'package:equatable/equatable.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';
// Si tienes categorías, impórtalas aquí, si no, eliminamos esa línea conflictiva
// import 'package:omnistream_iptv/features/playlist/domain/entities/category.dart';

abstract class PlaylistState extends Equatable {
  const PlaylistState();
  @override
  List<Object?> get props => [];
}

class PlaylistInitial extends PlaylistState {}

class PlaylistLoading extends PlaylistState {}

class PlaylistLoaded extends PlaylistState {
  final List<Channel> channels;
  // Eliminamos categories por ahora si está dando problemas de importación
  const PlaylistLoaded(this.channels);

  @override
  List<Object?> get props => [channels];
}

class PlaylistError extends PlaylistState {
  final String message;
  const PlaylistError(this.message);
  @override
  List<Object?> get props => [message];
}