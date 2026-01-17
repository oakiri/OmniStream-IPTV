import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/m3u_parser.dart';
import '../../../playlist/domain/entities/channel.dart';
import '../../domain/repositories/channel_repository.dart';
import '../datasources/channel_remote_data_source.dart';
import '../datasources/firebase_channel_data_source.dart';

class ChannelRepositoryImpl implements ChannelRepository {
  final ChannelRemoteDataSource remoteDataSource;
  final FirebaseChannelDataSource firebaseDataSource;

  const ChannelRepositoryImpl({
    required this.remoteDataSource,
    required this.firebaseDataSource,
  });

  @override
  Future<Either<Failure, List<Channel>>> getChannels(String playlistUrl) async {
    try {
      final m3uContent = await remoteDataSource.getM3UContent(playlistUrl);
      final channels = M3uParser.parse(m3uContent);
      return Right(channels);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Channel>>> getChannelsPaginated(
    String playlistId, {
    int limit = 50,
  }) async {
    try {
      // El datasource ya trae un "primer chunk". Aquí solo recortamos por seguridad.
      final channels = await firebaseDataSource.getChannels(playlistId);
      if (channels.length <= limit) return Right(channels);
      return Right(channels.take(limit).toList(growable: false));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncWithFirestore(
    String playlistId,
    List<Channel> channels, {
    void Function(int current, int total)? onProgress,
  }) async {
    try {
      await firebaseDataSource.syncChannels(
        playlistId,
        channels,
        onProgress: onProgress,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
