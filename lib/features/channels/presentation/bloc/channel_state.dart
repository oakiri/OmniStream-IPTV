import 'package:equatable/equatable.dart';
import 'package:omnistream_iptv/features/channels/domain/entities/channel.dart';

abstract class ChannelState extends Equatable {
  const ChannelState();

  @override
  List<Object?> get props => [];
}

class ChannelInitial extends ChannelState {}

class ChannelLoading extends ChannelState {}

class ChannelSyncing extends ChannelState {
  final int current;
  final int total;
  final double progress;

  const ChannelSyncing({required this.current, required this.total}) 
      : progress = total > 0 ? current / total : 0;

  @override
  List<Object?> get props => [current, total, progress];
}

class ChannelLoaded extends ChannelState {
  final List<Channel> channels;
  final bool hasReachedMax;

  const ChannelLoaded(this.channels, {this.hasReachedMax = false});

  @override
  List<Object?> get props => [channels, hasReachedMax];
}

class ChannelError extends ChannelState {
  final String message;

  const ChannelError(this.message);

  @override
  List<Object?> get props => [message];
}
