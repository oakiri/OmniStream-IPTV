import 'package:dartz/dartz.dart';
import 'package:omnistream_iptv/core/error/failure.dart';
import 'package:omnistream_iptv/features/channels/data/datasources/channel_remote_data_source.dart';
import 'package:omnistream_iptv/features/channels/data/datasources/firebase_channel_data_source.dart';
import 'package:omnistream_iptv/features/channels/domain/entities/channel_old.dart';
import 'package:omnistream_iptv/features/channels/domain/repositories/channel_repository.dart';

class ChannelRepositoryImpl implements ChannelRepository {
  final ChannelRemoteDataSource remoteDataSource;
  final FirebaseChannelDataSource firebaseDataSource;

  ChannelRepositoryImpl({
    required this.remoteDataSource,
    required this.firebaseDataSource,
  });

  @override
  Future<Either<Failure, List<ChannelOld>>> getChannels(
      String playlistUrl) async {
    try {
      final channels = await remoteDataSource.fetchChannels(playlistUrl);

      // Cache best-effort en Firebase (no debe romper UX si falla)
      try {
        await firebaseDataSource.cacheChannels(channels);
      } catch (_) {}

      return Right(channels);
    } catch (e) {
      return Left(ServerFailure('Error al cargar canales: $e'));
    }
  }
}
