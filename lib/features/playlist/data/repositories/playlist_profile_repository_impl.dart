import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:omnistream_iptv/core/error/failure.dart';
import 'package:omnistream_iptv/features/playlist/data/datasources/playlist_profile_local_data_source.dart';
import 'package:omnistream_iptv/features/playlist/data/models/playlist_profile_model.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/playlist_profile.dart';
import 'package:omnistream_iptv/features/playlist/domain/repositories/playlist_profile_repository.dart';

class PlaylistProfileRepositoryImpl implements PlaylistProfileRepository {
  final PlaylistProfileLocalDataSource localDataSource;
  final FirebaseAuth? firebaseAuth;

  PlaylistProfileRepositoryImpl({
    required this.localDataSource,
    this.firebaseAuth,
  });

  @override
  Future<Either<Failure, void>> addPlaylistProfile(PlaylistProfile profile) async {
    try {
      final user = firebaseAuth?.currentUser;
      
      // Convertimos a modelo pasando TODOS los datos
      final profileModel = PlaylistProfileModel(
        id: profile.id,
        name: profile.name,
        url: profile.url,
        userId: user?.uid ?? 'local',
        type: profile.type,         // <-- Pasamos el tipo
        lastUsed: profile.lastUsed, // <-- Pasamos lastUsed
      );
      
      await localDataSource.cachePlaylistProfile(profileModel);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePlaylistProfile(String id) async {
    try {
      await localDataSource.deletePlaylistProfile(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PlaylistProfile>>> getPlaylistProfiles() async {
    try {
      final localProfiles = await localDataSource.getLastPlaylistProfiles();
      return Right(localProfiles);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}