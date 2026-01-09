import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omnistream_iptv/features/playlist/domain/usecases/get_playlist.dart';
import 'package:omnistream_iptv/features/playlist/domain/usecases/toggle_favorite.dart';
// Usamos imports normales en lugar de 'part'
import 'package:omnistream_iptv/features/playlist/presentation/bloc/playlist_event.dart';
import 'package:omnistream_iptv/features/playlist/presentation/bloc/playlist_state.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';
import 'dart:isolate';

class PlaylistBloc extends Bloc<PlaylistEvent, PlaylistState> {
  final GetPlaylist getPlaylist;
  final ToggleFavorite toggleFavorite;

  PlaylistBloc({
    required this.getPlaylist,
    required this.toggleFavorite,
  }) : super(PlaylistInitial()) {
    on<LoadPlaylist>(_onLoadPlaylist);
    on<ToggleFavoriteChannel>(_onToggleFavoriteChannel);
  }

  Future<void> _onLoadPlaylist(LoadPlaylist event, Emitter<PlaylistState> emit) async {
    emit(PlaylistLoading());
    final result = await getPlaylist(event.url);
    result.fold(
      (failure) => emit(PlaylistError(failure.toString())),
      (channels) => emit(PlaylistLoaded(channels)),
    );
  }

  Future<void> _onToggleFavoriteChannel(ToggleFavoriteChannel event, Emitter<PlaylistState> emit) async {
    await toggleFavorite(event.channel);
  }

  static Future<List<Channel>> filterChannelsInIsolate(List<Channel> channels, String query) async {
    if (query.isEmpty) return channels;
    return Isolate.run(() {
      return channels.where((c) => c.name.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }
}