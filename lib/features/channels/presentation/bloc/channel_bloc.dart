import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omnistream_iptv/features/channels/domain/usecases/get_channels.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_event.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_state.dart';

class ChannelBloc extends Bloc<ChannelEvent, ChannelState> {
  final GetChannels getChannels;

  ChannelBloc({required this.getChannels}) : super(ChannelInitial()) {
    on<LoadChannels>((event, emit) async {
      emit(ChannelLoading());
      final failureOrChannels = await getChannels(event.url);
      failureOrChannels.fold(
        (failure) => emit(ChannelError(failure.message)),
        (channels) => emit(ChannelLoaded(channels)),
      );
    });
  }
}
