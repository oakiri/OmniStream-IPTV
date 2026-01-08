import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:omnistream_iptv/core/errors/failures.dart';
import 'package:omnistream_iptv/core/errors/exceptions.dart';
import 'package:omnistream_iptv/core/utils/m3u_parser.dart';
import 'package:omnistream_iptv/features/channels/data/datasources/channel_remote_data_source.dart';
import 'package:omnistream_iptv/features/channels/data/datasources/firebase_channel_data_source.dart';
import 'package:omnistream_iptv/features/channels/domain/entities/channel.dart';
import 'package:omnistream_iptv/features/channels/domain/repositories/channel_repository.dart';

class ChannelRepositoryImpl implements ChannelRepository {
  final ChannelRemoteDataSource remoteDataSource;
  final FirebaseChannelDataSource firebaseDataSource;

  ChannelRepositoryImpl({
    required this.remoteDataSource,
    required this.firebaseDataSource,
  });

  @override
  Future<Either<Failure, List<Channel>>> getChannels(String url) async {
    try {
      final m3uContent = await remoteDataSource.getM3UContent(url);
      final channels = await compute(M3UParser.parse, m3uContent);
      return Right(channels);
    } on ServerException {
      return Left(ServerFailure(message: 'Failed to fetch channels from URL'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncWithFirestore(
    String playlistId, 
    List<Channel> channels, 
    {Function(int, int)? onProgress}
  ) async {
    try {
      // Dividir canales en lotes de 500 (límite de Firestore Batch)
      const int batchSize = 500;
      for (var i = 0; i < channels.length; i += batchSize) {
        final end = (i + batchSize < channels.length) ? i + batchSize : channels.length;
        final batchChannels = channels.sublist(i, end);
        
        await firebaseDataSource.syncChannels(playlistId, batchChannels);
        
        if (onProgress != null) {
          onProgress(end, channels.length);
        }
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error syncing with Firestore: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Channel>>> getChannelsPaginated(String playlistId, {int limit = 50}) async {
    try {
      final channels = await firebaseDataSource.getChannelsPaginated(playlistId, limit: limit);
      return Right(channels);
    } catch (e) {
      return Left(ServerFailure(message: 'Error fetching paginated channels: ${e.toString()}'));
    }
  }
}
