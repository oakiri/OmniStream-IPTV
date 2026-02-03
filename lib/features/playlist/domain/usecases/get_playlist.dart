import 'package:dartz/dartz.dart';
import 'package:omnistream_iptv/core/error/failure.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';
import 'package:omnistream_iptv/features/playlist/domain/repositories/playlist_repository.dart';

class GetPlaylist {
  final PlaylistRepository repository;

  GetPlaylist(this.repository);

  Future<Either<Failure, List<Channel>>> call(String url) async {
    print('[GetPlaylist] Iniciando descarga desde: $url');
    try {
      final result = await repository.getChannels(url);
      result.fold(
        (failure) {
          print('[GetPlaylist] Fallo en repositorio: $failure');
        },
        (channels) {
          print('[GetPlaylist] Éxito: ${channels.length} canales obtenidos');
        },
      );
      return result;
    } catch (e) {
      print('[GetPlaylist] Error inesperado: $e');
      rethrow;
    }
  }
}
