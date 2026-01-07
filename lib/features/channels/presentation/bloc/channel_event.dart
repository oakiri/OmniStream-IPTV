import 'package:equatable/equatable.dart';

abstract class ChannelEvent extends Equatable {
  const ChannelEvent();

  @override
  List<Object> get props => [];
}

class LoadChannels extends ChannelEvent {
  final String url;

  const LoadChannels(this.url);

  @override
  List<Object> get props => [url];
}
