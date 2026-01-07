import 'package:dartz/dartz.dart';
import 'package:omnistream_iptv/core/errors/failures.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';

abstract class FavoriteRepository {
  Future<Either<Failure, void>> toggleFavorite(Channel channel);
  Future<Either<Failure, List<Channel>>> getFavorites();
  Future<Either<Failure, bool>> isFavorite(String channelId);
}
