import 'package:dartz/dartz.dart';
import 'package:omnistream_iptv/core/errors/failures.dart';
import 'package:omnistream_iptv/features/channels/domain/entities/channel.dart';

abstract class ChannelRepository {
  Future<Either<Failure, List<Channel>>> getChannels(String url);
  Future<Either<Failure, void>> syncWithFirestore(String playlistId, List<Channel> channels, {Function(int, int)? onProgress});
  Future<Either<Failure, List<Channel>>> getChannelsPaginated(String playlistId, {int limit = 50});
}
