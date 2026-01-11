import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:omnistream_iptv/core/error/failure.dart';
import 'package:omnistream_iptv/features/playlist/data/datasources/playlist_profile_local_data_source.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/playlist_profile.dart';
import 'package:omnistream_iptv/features/playlist/domain/repositories/playlist_profile_repository.dart';
import 'package:omnistream_iptv/features/playlist/data/models/playlist_profile_model.dart';

class PlaylistProfileRepositoryImpl implements PlaylistProfileRepository {
  final PlaylistProfileLocalDataSource localDataSource;
  final FirebaseFirestore? firestore;
  final FirebaseAuth? firebaseAuth;

  PlaylistProfileRepositoryImpl({
    required this.localDataSource,
    this.firestore,
    this.firebaseAuth,
  });

  @override
  Future<Either<Failure, List<PlaylistProfile>>> getPlaylistProfiles() async {
    try {
      final localProfiles = await localDataSource.getPlaylistProfiles();
      return Right(localProfiles);
    } catch (e) {
      return const Left(CacheFailure(message: 'Error al cargar perfiles locales'));
    }
  }

  @override
  Future<Either<Failure, void>> addPlaylistProfile(PlaylistProfile profile) async {
    try {
      final user = firebaseAuth?.currentUser;
      final model = PlaylistProfileModel(
        id: profile.id,
        name: profile.name,
        url: profile.url,
        userId: user?.uid ?? 'local',
      );
      
      await localDataSource.savePlaylistProfile(model);

      if (user != null && firestore != null) {
        await firestore!
            .collection('users')
            .doc(user.uid)
            .collection('playlists')
            .doc(model.id)
            .set(model.toJson());
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePlaylistProfile(String id) async {
    try {
      // 1. Borrar de Hive
      await localDataSource.deletePlaylistProfile(id);

      // 2. Borrar de Firestore
      final user = firebaseAuth?.currentUser;
      if (user != null && firestore != null) {
        await firestore!
            .collection('users')
            .doc(user.uid)
            .collection('playlists')
            .doc(id)
            .delete();
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}