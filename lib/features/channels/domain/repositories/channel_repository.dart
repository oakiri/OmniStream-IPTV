import 'package:dartz/dartz.dart';
import 'package:omnistream_iptv/core/error/failure.dart'; // <--- CORREGIDO (Singular)
// Usamos la entidad de playlist para evitar conflictos de tipos
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';

abstract class ChannelRepository {
  Future<Either<Failure, List<Channel>>> getChannels(String url);
  Future<Either<Failure, void>> syncWithFirestore(
      String playlistId, List<Channel> channels,
      {Function(int, int)? onProgress});
  Future<Either<Failure, List<Channel>>> getChannelsPaginated(String playlistId,
      {int limit = 50});
}
