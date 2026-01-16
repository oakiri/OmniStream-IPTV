import 'package:equatable/equatable.dart';

import '../../domain/entities/channel.dart';

abstract class PlaylistState extends Equatable {
  const PlaylistState();

  @override
  List<Object?> get props => [];
}

class PlaylistInitial extends PlaylistState {
  const PlaylistInitial();
}

class PlaylistLoading extends PlaylistState {
  const PlaylistLoading();
}

class PlaylistLoaded extends PlaylistState {
  final List<Channel> channels;
  final List<Channel> filteredChannels;
  final String query;

  const PlaylistLoaded({
    required this.channels,
    required this.filteredChannels,
    required this.query,
  });

  PlaylistLoaded copyWith({
    List<Channel>? channels,
    List<Channel>? filteredChannels,
    String? query,
  }) {
    return PlaylistLoaded(
      channels: channels ?? this.channels,
      filteredChannels: filteredChannels ?? this.filteredChannels,
      query: query ?? this.query,
    );
  }

  @override
  List<Object?> get props => [channels, filteredChannels, query];
}

class PlaylistFiltering extends PlaylistState {
  final List<Channel> channels;
  final String query;

  const PlaylistFiltering({
    required this.channels,
    required this.query,
  });

  @override
  List<Object?> get props => [channels, query];
}

class PlaylistError extends PlaylistState {
  final String message;

  const PlaylistError(this.message);

  @override
  List<Object?> get props => [message];
}
