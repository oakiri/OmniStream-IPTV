import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/playlist_profile.dart';
import '../../domain/repositories/playlist_profile_repository.dart';
import '../datasources/playlist_profile_local_data_source.dart';
import '../datasources/playlist_profile_remote_data_source.dart';
import '../models/playlist_profile_model.dart';

class PlaylistProfileRepositoryImpl implements PlaylistProfileRepository {
  final PlaylistProfileLocalDataSource localDataSource;
  final PlaylistProfileRemoteDataSource remoteDataSource;
  final FirebaseAuth firebaseAuth;

  const PlaylistProfileRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.firebaseAuth,
  });

  String get _userId => firebaseAuth.currentUser?.uid ?? 'anonymous';

  @override
  Future<Either<Failure, List<PlaylistProfile>>> getPlaylistProfiles() async {
    try {
      // 1) Local first (fast UX)
      final local = await localDataSource.getPlaylistProfiles();
      if (local.isNotEmpty) {
        return Right(local.map<PlaylistProfile>((e) => e).toList());
      }

      // 2) Remote fallback
      final remote = await remoteDataSource.getPlaylistProfiles(_userId);

      // 3) Cache to local
      for (final p in remote) {
        await localDataSource.savePlaylistProfile(p);
      }

      return Right(remote.map<PlaylistProfile>((e) => e).toList());
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addPlaylistProfile(PlaylistProfile profile) async {
    try {
      final model = profile is PlaylistProfileModel
          ? profile
          : PlaylistProfileModel.fromEntity(profile);

      await localDataSource.savePlaylistProfile(model);

      // Remote best-effort (don't break UX if it fails)
      try {
        await remoteDataSource.addPlaylistProfile(_userId, model);
      } catch (_) {}

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePlaylistProfile(String id) async {
    try {
      await localDataSource.deletePlaylistProfile(id);

      try {
        await remoteDataSource.deletePlaylistProfile(_userId, id);
      } catch (_) {}

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}
