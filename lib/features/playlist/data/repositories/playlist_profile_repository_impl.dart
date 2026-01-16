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

  PlaylistProfileRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.firebaseAuth,
  });

  String get _userId => firebaseAuth.currentUser?.uid ?? 'anonymous';

  @override
  Future<Either<Failure, List<PlaylistProfile>>> getPlaylistProfiles() async {
    try {
      // 1) Intentamos local
      final local = await localDataSource.getProfiles();
      final localEntities = local.map<PlaylistProfile>((e) => e).toList();

      // 2) Si hay local, devolvemos rápido (UX instantánea)
      if (localEntities.isNotEmpty) return Right(localEntities);

      // 3) Si no hay local, probamos remoto
      final remote = await remoteDataSource.getPlaylistProfiles(_userId);

      // guardamos remoto en local para siguientes arranques
      for (final p in remote) {
        await localDataSource.saveProfile(p);
      }

      return Right(remote.map<PlaylistProfile>((e) => e).toList());
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addPlaylistProfile(
      PlaylistProfile profile) async {
    try {
      final model = profile is PlaylistProfileModel
          ? profile
          : PlaylistProfileModel.fromEntity(profile);

      await localDataSource.saveProfile(model);

      // remoto best-effort (si falla no rompemos UX)
      try {
        await remoteDataSource.saveProfile(_userId, model);
      } catch (_) {}

      return const Right(null);
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePlaylistProfile(String id) async {
    try {
      await localDataSource.deleteProfile(id);

      try {
        await remoteDataSource.deleteProfile(_userId, id);
      } catch (_) {}

      return const Right(null);
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }
}
