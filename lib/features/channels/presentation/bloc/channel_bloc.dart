import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omnistream_iptv/features/channels/domain/usecases/get_channels.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_event.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_state.dart';
import 'package:omnistream_iptv/core/error/failure.dart';

class ChannelBloc extends Bloc<ChannelEvent, ChannelState> {
  final GetChannels getChannels;

  ChannelBloc({required this.getChannels}) : super(ChannelInitial()) {
    on<LoadChannels>(_onLoadChannels);
    on<SearchChannels>(_onSearchChannels);
    on<SelectCategory>(_onSelectCategory);
  }

  Future<void> _onLoadChannels(LoadChannels event, Emitter<ChannelState> emit) async {
    emit(ChannelLoading());
    final result = await getChannels(event.url);
    
    result.fold(
      (failure) => emit(ChannelError(_mapFailureToMessage(failure))),
      (channels) {
        // 1. Extraer categorías ÚNICAS de la lista
        // Usamos un Set para que no se repitan y luego a Lista
        final groups = channels
            .map((c) => c.group ?? "Otros") // Si no tiene grupo, va a "Otros"
            .toSet()
            .toList();
        
        // Ordenamos alfabéticamente
        groups.sort();
        
        // Añadimos "All" al principio siempre
        final categories = ["All", ...groups];

        emit(ChannelLoaded(
          allChannels: channels,
          displayChannels: channels, // Al principio se ven todos
          categories: categories,
          selectedCategory: "All",
        ));
      },
    );
  }

  void _onSearchChannels(SearchChannels event, Emitter<ChannelState> emit) {
    if (state is ChannelLoaded) {
      final currentState = state as ChannelLoaded;
      
      // Buscamos SIEMPRE en 'allChannels' (ignorando la categoría seleccionada para buscar globalmente)
      // O si prefieres buscar solo dentro de la categoría, cambia allChannels por una lista filtrada previa.
      // Por ahora, búsqueda global estilo Smarters:
      final filtered = currentState.allChannels
          .where((channel) => channel.name.toLowerCase().contains(event.query.toLowerCase()))
          .toList();
          
      emit(currentState.copyWith(
        displayChannels: filtered,
        selectedCategory: "All" // Al buscar, reseteamos a "All" para ver resultados de todas partes
      ));
    }
  }

  void _onSelectCategory(SelectCategory event, Emitter<ChannelState> emit) {
    if (state is ChannelLoaded) {
      final currentState = state as ChannelLoaded;
      
      List<dynamic> filtered; // Usamos dynamic temporalmente para evitar problemas de tipo, luego casteamos implícitamente

      if (event.category == "All") {
        // Si es "All", mostramos todo
        filtered = currentState.allChannels;
      } else {
        // Filtramos por el grupo exacto
        filtered = currentState.allChannels
            .where((channel) => (channel.group ?? "Otros") == event.category)
            .toList();
      }

      emit(currentState.copyWith(
        displayChannels: List.from(filtered),
        selectedCategory: event.category,
      ));
    }
  }

  String _mapFailureToMessage(Failure failure) {
    return "Error al cargar canales: ${failure.toString()}";
  }
}