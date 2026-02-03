import 'package:dartz/dartz.dart';
import 'package:omnistream_iptv/core/error/failure.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/playlist_profile.dart';

abstract class PlaylistProfileRepository {
  Future<Either<Failure, void>> addPlaylistProfile(PlaylistProfile profile);
  Future<Either<Failure, void>> updatePlaylistProfile(PlaylistProfile profile);
  Future<Either<Failure, void>> deletePlaylistProfile(String id);
  Future<Either<Failure, List<PlaylistProfile>>> getPlaylistProfiles();
}
