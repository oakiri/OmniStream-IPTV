import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/m3u_parser.dart';
import '../../../playlist/data/models/channel_model.dart';
import '../../../playlist/domain/entities/channel.dart';
import '../../domain/repositories/channel_repository.dart';
import '../datasources/channel_remote_data_source.dart';
import '../datasources/firebase_channel_data_source.dart';

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
      final channels = M3uParser.parse(m3uContent);
      return Right(channels);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncWithFirestore(
    String playlistId,
    List<Channel> channels,
  ) async {
    try {
      final models = channels.map(ChannelModel.fromEntity).toList();
      await firebaseDataSource.syncChannels(playlistId, models);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Channel>>> getChannelsPaginated(
    String playlistId,
  ) async {
    try {
      final models = await firebaseDataSource.getChannels(playlistId);
      final entities = models.map<Channel>((m) => m).toList();
      return Right(entities);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
