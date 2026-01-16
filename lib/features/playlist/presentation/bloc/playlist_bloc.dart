import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/channel.dart';
import '../../domain/usecases/get_playlist.dart';
import '../../domain/usecases/toggle_favorite.dart';
import 'playlist_event.dart';
import 'playlist_state.dart';

class PlaylistBloc extends Bloc<PlaylistEvent, PlaylistState> {
  final GetPlaylist getPlaylist;
  final ToggleFavorite toggleFavorite;

  Timer? _debounce;

  PlaylistBloc(this.getPlaylist, this.toggleFavorite)
      : super(const PlaylistInitial()) {
    on<LoadPlaylist>(_onLoadPlaylist);
    on<FilterChannels>(_onFilterChannels);
    on<ClearFilter>(_onClearFilter);
    on<ToggleFavoriteChannel>(_onToggleFavorite);
  }

  Future<void> _onLoadPlaylist(
    LoadPlaylist event,
    Emitter<PlaylistState> emit,
  ) async {
    emit(const PlaylistLoading());

    final result = await getPlaylist(event.url);

    result.fold(
      (failure) => emit(PlaylistError(failure.message)),
      (channels) {
        final safe = channels;
        emit(PlaylistLoaded(
          channels: safe,
          filteredChannels: safe,
          query: '',
        ));
      },
    );
  }

  Future<void> _onFilterChannels(
    FilterChannels event,
    Emitter<PlaylistState> emit,
  ) async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      final current = state;
      final q = event.query.trim().toLowerCase();

      if (current is PlaylistLoaded) {
        if (q.isEmpty) {
          emit(current.copyWith(filteredChannels: current.channels, query: ''));
          return;
        }

        emit(PlaylistFiltering(channels: current.channels, query: event.query));

        final filtered = _applyFilter(current.channels, q);

        emit(PlaylistLoaded(
          channels: current.channels,
          filteredChannels: filtered,
          query: event.query,
        ));
      } else if (current is PlaylistFiltering) {
        final filtered =
            q.isEmpty ? current.channels : _applyFilter(current.channels, q);

        emit(PlaylistLoaded(
          channels: current.channels,
          filteredChannels: filtered,
          query: event.query,
        ));
      }
    });
  }

  Future<void> _onClearFilter(
    ClearFilter event,
    Emitter<PlaylistState> emit,
  ) async {
    final current = state;
    if (current is PlaylistLoaded) {
      emit(current.copyWith(filteredChannels: current.channels, query: ''));
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavoriteChannel event,
    Emitter<PlaylistState> emit,
  ) async {
    await toggleFavorite(event.channel);
  }

  List<Channel> _applyFilter(List<Channel> channels, String qLower) {
    return channels.where((c) {
      final name = (c.name ?? '').toLowerCase();
      final group = (c.group ?? '').toLowerCase();
      return name.contains(qLower) || group.contains(qLower);
    }).toList(growable: false);
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
