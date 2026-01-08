import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omnistream_iptv/features/channels/domain/repositories/channel_repository.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_event.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_state.dart';

class ChannelBloc extends Bloc<ChannelEvent, ChannelState> {
  final ChannelRepository repository;

  ChannelBloc({required this.repository}) : super(ChannelInitial()) {
    on<SyncChannelsWithFirestore>(_onSyncChannels);
    on<LoadChannels>(_onLoadChannels);
    on<LoadMoreChannels>(_onLoadMoreChannels);
  }

  Future<void> _onSyncChannels(
    SyncChannelsWithFirestore event,
    Emitter<ChannelState> emit,
  ) async {
    emit(ChannelLoading());
    
    // 1. Obtener canales desde M3U
    final failureOrChannels = await repository.getChannels(event.url);
    
    await failureOrChannels.fold(
      (failure) async => emit(ChannelError(failure.message)),
      (channels) async {
        // 2. Sincronizar con Firestore con progreso
        final syncResult = await repository.syncWithFirestore(
          event.playlistId, 
          channels,
          onProgress: (current, total) {
            emit(ChannelSyncing(current: current, total: total));
          },
        );

        syncResult.fold(
          (failure) => emit(ChannelError(failure.message)),
          (_) => add(LoadChannels(url: event.url, playlistId: event.playlistId)),
        );
      },
    );
  }

  Future<void> _onLoadChannels(
    LoadChannels event,
    Emitter<ChannelState> emit,
  ) async {
    emit(ChannelLoading());
    final result = await repository.getChannelsPaginated(event.playlistId, limit: 50);
    result.fold(
      (failure) => emit(ChannelError(failure.message)),
      (channels) => emit(ChannelLoaded(channels, hasReachedMax: channels.length < 50)),
    );
  }

  Future<void> _onLoadMoreChannels(
    LoadMoreChannels event,
    Emitter<ChannelState> emit,
  ) async {
    if (state is! ChannelLoaded || (state as ChannelLoaded).hasReachedMax) return;

    final currentState = state as ChannelLoaded;
    final result = await repository.getChannelsPaginated(event.playlistId, limit: 50);
    
    result.fold(
      (failure) => emit(ChannelError(failure.message)),
      (newChannels) {
        emit(ChannelLoaded(
          currentState.channels + newChannels,
          hasReachedMax: newChannels.length < 50,
        ));
      },
    );
  }
}
