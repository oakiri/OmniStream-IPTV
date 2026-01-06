import 'package:dartz/dartz.dart';
import 'package:omnistream_iptv/core/error/failure.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';
import 'package:omnistream_iptv/features/playlist/domain/repositories/playlist_repository.dart';

class GetPlaylist {
  final PlaylistRepository repository;

  GetPlaylist(this.repository);

  Future<Either<Failure, List<Channel>>> call(String url) async {
    return await repository.getChannels(url);
  }
}
