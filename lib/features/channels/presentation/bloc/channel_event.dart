import 'package:equatable/equatable.dart';

abstract class ChannelEvent extends Equatable {
  const ChannelEvent();

  @override
  List<Object?> get props => [];
}

class LoadChannels extends ChannelEvent {
  final String url;
  final String playlistId;

  const LoadChannels({required this.url, required this.playlistId});

  @override
  List<Object?> get props => [url, playlistId];
}

class SyncChannelsWithFirestore extends ChannelEvent {
  final String playlistId;
  final String url;

  const SyncChannelsWithFirestore({required this.playlistId, required this.url});

  @override
  List<Object?> get props => [playlistId, url];
}

class LoadMoreChannels extends ChannelEvent {
  final String playlistId;

  const LoadMoreChannels(this.playlistId);

  @override
  List<Object?> get props => [playlistId];
}

// --- CLASES A�ADIDAS ---

class SearchChannels extends ChannelEvent {
  final String query;
  const SearchChannels(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterChannelsByGroup extends ChannelEvent {
  final String group;
  const FilterChannelsByGroup(this.group);

  @override
  List<Object?> get props => [group];
}