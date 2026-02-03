import 'package:equatable/equatable.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';

abstract class ChannelState extends Equatable {
  const ChannelState();
  
  @override
  List<Object> get props => [];
}

class ChannelInitial extends ChannelState {}

class ChannelLoading extends ChannelState {}

class ChannelLoaded extends ChannelState {
  final List<Channel> allChannels;      // Todos los canales
  final List<Channel> displayChannels;  // Los que se ven ahora
  
  // NUEVAS VARIABLES PARA CATEGORÍAS
  final List<String> categories;        // Lista de grupos: ["All", "Deportes", ...]
  /// Categorías seleccionadas (multi-select). Vacío == "All".
  final Set<String> selectedCategories;

  /// Búsqueda activa.
  final String searchQuery;

  const ChannelLoaded({
    required this.allChannels,
    required this.displayChannels,
    required this.categories,
    required this.selectedCategories,
    required this.searchQuery,
  });

  List<Channel> get channels => displayChannels;

  ChannelLoaded copyWith({
    List<Channel>? allChannels,
    List<Channel>? displayChannels,
    List<String>? categories,
    Set<String>? selectedCategories,
    String? searchQuery,
  }) {
    return ChannelLoaded(
      allChannels: allChannels ?? this.allChannels,
      displayChannels: displayChannels ?? this.displayChannels,
      categories: categories ?? this.categories,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object> get props => [allChannels, displayChannels, categories, selectedCategories, searchQuery];
}

class ChannelError extends ChannelState {
  final String message;
  const ChannelError(this.message);
  @override
  List<Object> get props => [message];
}