import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/category.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';
import 'package:omnistream_iptv/features/playlist/domain/usecases/get_playlist.dart';

part 'playlist_event.dart';
part 'playlist_state.dart';

class PlaylistBloc extends Bloc<PlaylistEvent, PlaylistState> {
  final GetPlaylist getPlaylist;

  PlaylistBloc({required this.getPlaylist}) : super(PlaylistInitial()) {
    on<LoadPlaylist>((event, emit) async {
      print('🎬 Iniciando carga de canales...');
      print('📍 URL de la lista: ${event.url}');
      emit(PlaylistLoading());
      try {
        final failureOrChannels = await getPlaylist(event.url);
        failureOrChannels.fold(
          (failure) {
            print('❌ Error cargando canales: $failure');
            emit(PlaylistError(failure.toString()));
          },
          (channels) {
            print('✓ Carga completada. Total canales: ${channels.length}');
            final categories = _groupChannelsIntoCategories(channels);
            print('✓ Categorías agrupadas: ${categories.length}');
            emit(PlaylistLoaded(channels: channels, categories: categories));
          },
        );
      } catch (e) {
        print('❌ Error inesperado cargando canales: $e');
        emit(PlaylistError('Error inesperado: $e'));
      }
    });
  }

  List<Category> _groupChannelsIntoCategories(List<Channel> channels) {
    final categories = <String, List<String>>{};
    for (final channel in channels) {
      final group = channel.group ?? 'Uncategorized';
      if (!categories.containsKey(group)) {
        categories[group] = [];
      }
      categories[group]!.add(channel.id);
    }
    return categories.entries
        .map((entry) => Category(name: entry.key, channels: entry.value))
        .toList();
  }
}
