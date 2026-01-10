import 'package:equatable/equatable.dart';

abstract class ChannelEvent extends Equatable {
  const ChannelEvent();

  @override
  List<Object> get props => [];
}

class LoadChannels extends ChannelEvent {
  final String url;
  final String playlistId;

  const LoadChannels({required this.url, required this.playlistId});

  @override
  List<Object> get props => [url, playlistId];
}

class SearchChannels extends ChannelEvent {
  final String query;
  const SearchChannels(this.query);

  @override
  List<Object> get props => [query];
}

// NUEVO EVENTO: Seleccionar Categoría
class SelectCategory extends ChannelEvent {
  final String category; // Ej: "Deportes", "Cine", "All"

  const SelectCategory(this.category);

  @override
  List<Object> get props => [category];
}