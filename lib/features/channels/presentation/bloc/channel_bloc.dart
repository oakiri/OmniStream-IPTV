import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:omnistream_iptv/core/error/failure.dart';
import 'package:omnistream_iptv/features/channels/domain/usecases/get_channels.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_event.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_state.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';

class ChannelBloc extends Bloc<ChannelEvent, ChannelState> {
  final GetChannels getChannels;

  ChannelBloc({required this.getChannels}) : super(ChannelInitial()) {
    on<LoadChannels>(_onLoadChannels);
    on<SearchChannels>(_onSearchChannels);
    on<SelectCategory>(_onSelectCategory);
  }

  Future<void> _onLoadChannels(LoadChannels event, Emitter<ChannelState> emit) async {
    emit(ChannelLoading());
    final result = await getChannels(event.url);

    result.fold(
      (failure) => emit(ChannelError(_mapFailureToMessage(failure))),
      (channels) {
        // Extraer categorías únicas.
        final groups = channels
            .map((c) => (c.group ?? c.groupTitle ?? 'Otros'))
            .toSet()
            .toList();
        groups.sort();
        final categories = ['All', ...groups];

        emit(ChannelLoaded(
          allChannels: channels,
          displayChannels: channels,
          categories: categories,
          selectedCategories: const <String>{}, // vacío == All
          searchQuery: '',
        ));
      },
    );
  }

  void _onSearchChannels(SearchChannels event, Emitter<ChannelState> emit) {
    if (state is! ChannelLoaded) return;
    final s = state as ChannelLoaded;

    final q = event.query;
    final filtered = _applyFilters(
      all: s.allChannels,
      selectedCategories: s.selectedCategories,
      searchQuery: q,
    );

    emit(s.copyWith(
      searchQuery: q,
      displayChannels: filtered,
    ));
  }

  void _onSelectCategory(SelectCategory event, Emitter<ChannelState> emit) {
    if (state is! ChannelLoaded) return;
    final s = state as ChannelLoaded;

    final next = <String>{...s.selectedCategories};

    if (event.category == 'All') {
      // "All" es exclusivo: limpia selección.
      next.clear();
    } else {
      // Multi-select: toggle.
      if (next.contains(event.category)) {
        next.remove(event.category);
      } else {
        next.add(event.category);
      }
    }

    final filtered = _applyFilters(
      all: s.allChannels,
      selectedCategories: next,
      searchQuery: s.searchQuery,
    );

    emit(s.copyWith(
      selectedCategories: next,
      displayChannels: filtered,
    ));
  }

  List<Channel> _applyFilters({
    required List<Channel> all,
    required Set<String> selectedCategories,
    required String searchQuery,
  }) {
    Iterable<Channel> res = all;

    // Filtrado por categorías (multi-select). Vacío => All.
    if (selectedCategories.isNotEmpty) {
      res = res.where((c) {
        final group = (c.group ?? c.groupTitle ?? 'Otros');
        return selectedCategories.contains(group);
      });
    }

    final q = searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      res = res.where((c) => c.name.toLowerCase().contains(q));
    }

    return res.toList();
  }

  String _mapFailureToMessage(Failure failure) {
    return 'Error al cargar canales: ${failure.toString()}';
  }
}
