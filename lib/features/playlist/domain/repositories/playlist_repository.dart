import 'package:dartz/dartz.dart';
import 'package:omnistream_iptv/core/error/failure.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';

abstract class PlaylistRepository {
  // Aseguramos que el nombre coincide con la implementaci�n
  Future<Either<Failure, List<Channel>>> getChannels(String url);
}
