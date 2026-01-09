import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omnistream_iptv/features/channels/domain/usecases/get_channels.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_event.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_state.dart';
import 'package:omnistream_iptv/core/error/failure.dart'; // <--- Import correcto

class ChannelBloc extends Bloc<ChannelEvent, ChannelState> {
  final GetChannels getChannels;

  ChannelBloc({required this.getChannels}) : super(ChannelInitial()) {
    on<LoadChannels>(_onLoadChannels);
    on<SearchChannels>(_onSearchChannels);
    on<FilterChannelsByGroup>(_onFilterChannelsByGroup);
    on<LoadMoreChannels>(_onLoadMoreChannels);
  }

  Future<void> _onLoadChannels(LoadChannels event, Emitter<ChannelState> emit) async {
    emit(ChannelLoading());
    final result = await getChannels(event.url);
    
    result.fold(
      // Asumimos que Failure tiene una propiedad message, si no, usamos toString()
      (failure) => emit(ChannelError(_mapFailureToMessage(failure))),
      (channels) => emit(ChannelLoaded(channels, hasReachedMax: false)),
    );
  }

  void _onSearchChannels(SearchChannels event, Emitter<ChannelState> emit) {
    if (state is ChannelLoaded) {
      final currentState = state as ChannelLoaded;
      final filtered = currentState.channels
          .where((channel) => channel.name.toLowerCase().contains(event.query.toLowerCase()))
          .toList();
      emit(ChannelLoaded(filtered, hasReachedMax: currentState.hasReachedMax));
    }
  }

  void _onFilterChannelsByGroup(FilterChannelsByGroup event, Emitter<ChannelState> emit) {
    if (state is ChannelLoaded) {
      final currentState = state as ChannelLoaded;
      final filtered = currentState.channels
          .where((channel) => channel.group == event.group) // Usamos .group que es el de playlist
          .toList();
      emit(ChannelLoaded(filtered, hasReachedMax: currentState.hasReachedMax));
    }
  }

  Future<void> _onLoadMoreChannels(LoadMoreChannels event, Emitter<ChannelState> emit) async {
    if (state is ChannelLoaded) {
      final currentState = state as ChannelLoaded;
      final result = await getChannels(event.playlistId); // Aqu� deber�as implementar paginaci�n real

      result.fold(
        (failure) => emit(ChannelError(_mapFailureToMessage(failure))),
        (newChannels) {
          emit(newChannels.isEmpty
              ? currentState.copyWith(hasReachedMax: true)
              : ChannelLoaded(
                  currentState.channels + newChannels,
                  hasReachedMax: false,
                ));
        },
      );
    }
  }

  String _mapFailureToMessage(Failure failure) {
    // Si tu clase Failure tiene una propiedad 'message', �sala: return failure.message;
    // Si no, devuelve un mensaje gen�rico o el toString:
    return "Error al cargar canales: ${failure.toString()}";
  }
}