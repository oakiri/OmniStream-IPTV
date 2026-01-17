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
      // 1) Intentamos local primero (UX instantánea)
      final local = await localDataSource.getPlaylistProfiles();
      if (local.isNotEmpty) {
        return Right(local.map<PlaylistProfile>((e) => e).toList());
      }

      // 2) Si no hay local, vamos a remoto
      final remote = await remoteDataSource.getProfiles(_userId);

      // 3) Cacheamos remoto en local para próximos arranques
      for (final p in remote) {
        await localDataSource.savePlaylistProfile(p);
      }

      return Right(remote.map<PlaylistProfile>((e) => e).toList());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addPlaylistProfile(PlaylistProfile profile) async {
    try {
      final model = profile is PlaylistProfileModel
          ? profile
          : PlaylistProfileModel.fromEntity(profile);

      // local primero
      await localDataSource.savePlaylistProfile(model);

      // remoto best-effort (no rompemos UX si falla)
      try {
        await remoteDataSource.saveProfile(_userId, model);
      } catch (_) {}

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePlaylistProfile(String id) async {
    try {
      await localDataSource.deletePlaylistProfile(id);
      try {
        await remoteDataSource.deleteProfile(_userId, id);
      } catch (_) {}
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLastUsed(String id, DateTime lastUsed) async {
    try {
      await localDataSource.updateLastUsed(id, lastUsed);
      try {
        await remoteDataSource.updateLastUsed(_userId, id, lastUsed);
      } catch (_) {}
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
