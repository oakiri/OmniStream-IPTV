import 'package:equatable/equatable.dart';
import 'package:omnistream_iptv/features/channels/domain/entities/channel.dart';

abstract class ChannelState extends Equatable {
  const ChannelState();

  @override
  List<Object> get props => [];
}

class ChannelInitial extends ChannelState {}

class ChannelLoading extends ChannelState {}

class ChannelLoaded extends ChannelState {
  final List<Channel> channels;

  const ChannelLoaded(this.channels);

  @override
  List<Object> get props => [channels];
}

class ChannelError extends ChannelState {
  final String message;

  const ChannelError(this.message);

  @override
  List<Object> get props => [message];
}
