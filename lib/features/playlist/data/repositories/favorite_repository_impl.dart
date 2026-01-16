import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:omnistream_iptv/core/error/failure.dart';
import 'package:omnistream_iptv/features/playlist/data/datasources/favorite_remote_data_source.dart';
import 'package:omnistream_iptv/features/playlist/data/models/favorite_channel_model.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';
import 'package:omnistream_iptv/features/playlist/domain/repositories/favorite_repository.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  final FavoriteRemoteDataSource remoteDataSource;
  final FirebaseAuth firebaseAuth;

  FavoriteRepositoryImpl({
    required this.remoteDataSource,
    required this.firebaseAuth,
  });

  String? get _userId => firebaseAuth.currentUser?.uid;

  @override
  Future<Either<Failure, void>> toggleFavorite(Channel channel) async {
    if (_userId == null)
      return Left(ServerFailure(message: 'User not authenticated'));

    try {
      final isFav = await isFavorite(channel.id);
      return isFav.fold(
        (failure) => Left(failure),
        (isCurrentlyFavorite) async {
          if (isCurrentlyFavorite) {
            await remoteDataSource.removeFavorite(_userId!, channel.id);
          } else {
            final favoriteModel = FavoriteChannelModel(
              id: channel.id,
              name: channel.name,
              logoUrl: channel.logoUrl,
              url: channel.url,
              group: channel.group,
              userId: _userId!,
            );
            await remoteDataSource.addFavorite(_userId!, favoriteModel);
          }
          return const Right(null);
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Channel>>> getFavorites() async {
    if (_userId == null)
      return Left(ServerFailure(message: 'User not authenticated'));

    try {
      final favorites = await remoteDataSource.getFavorites(_userId!);
      return Right(favorites);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isFavorite(String channelId) async {
    if (_userId == null)
      return Left(ServerFailure(message: 'User not authenticated'));

    try {
      final favorites = await remoteDataSource.getFavorites(_userId!);
      final isFav = favorites.any((fav) => fav.id == channelId);
      return Right(isFav);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
