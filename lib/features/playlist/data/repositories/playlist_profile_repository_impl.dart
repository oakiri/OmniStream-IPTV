import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:omnistream_iptv/core/errors/failures.dart';
import 'package:omnistream_iptv/features/playlist/data/datasources/playlist_profile_local_data_source.dart';
import 'package:omnistream_iptv/features/playlist/data/datasources/playlist_profile_remote_data_source.dart';
import 'package:omnistream_iptv/features/playlist/data/models/playlist_profile_model.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/playlist_profile.dart';
import 'package:omnistream_iptv/features/playlist/domain/repositories/playlist_profile_repository.dart';

class PlaylistProfileRepositoryImpl implements PlaylistProfileRepository {
  final PlaylistProfileLocalDataSource localDataSource;
  final PlaylistProfileRemoteDataSource remoteDataSource;
  final FirebaseAuth firebaseAuth;

  PlaylistProfileRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.firebaseAuth,
  });

  @override
  Future<Either<Failure, void>> addPlaylistProfile(PlaylistProfile profile) async {
    final user = firebaseAuth.currentUser;
    if (user == null) return Left(ServerFailure(message: 'User not logged in'));

    final profileModel = PlaylistProfileModel(
      id: profile.id,
      name: profile.name,
      url: profile.url,
      lastUpdated: profile.lastUpdated,
      isFavorite: profile.isFavorite,
    );

    try {
      await localDataSource.addPlaylistProfile(profileModel);
      await remoteDataSource.addPlaylistProfile(user.uid, profileModel);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deletePlaylistProfile(String id) async {
    final user = firebaseAuth.currentUser;
    if (user == null) return Left(ServerFailure(message: 'User not logged in'));

    try {
      await localDataSource.deletePlaylistProfile(id);
      await remoteDataSource.deletePlaylistProfile(user.uid, id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<PlaylistProfile>>> getPlaylistProfiles() async {
    final user = firebaseAuth.currentUser;
    if (user == null) return Left(ServerFailure(message: 'User not logged in'));

    try {
      final localProfiles = await localDataSource.getPlaylistProfiles();
      if (localProfiles.isNotEmpty) {
        return Right(localProfiles);
      }

      final remoteProfiles = await remoteDataSource.getPlaylistProfiles(user.uid);
      for (final profile in remoteProfiles) {
        await localDataSource.addPlaylistProfile(profile);
      }
      return Right(remoteProfiles);
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}
