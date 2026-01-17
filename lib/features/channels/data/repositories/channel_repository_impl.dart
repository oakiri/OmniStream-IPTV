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
  Future<Either<Failure, List<Channel>>> getChannels(String playlistUrl) async {
    try {
      final content = await remoteDataSource.getM3UContent(playlistUrl);
      final channels = M3uParser.parse(content);
      return Right(channels);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Channel>>> getChannelsPaginated(
    String playlistUrl, {
    int limit = 50,
  }) async {
    // Pagina inicial (no hay offset en la interfaz actual)
    final res = await getChannels(playlistUrl);
    return res.map((list) {
      if (list.length <= limit) return list;
      return list.sublist(0, limit);
    });
  }

  @override
  Future<Either<Failure, void>> syncWithFirestore(
    String playlistId,
    List<Channel> channels, {
    void Function(int current, int total)? onProgress,
  }) async {
    try {
      final total = channels.length;
      final models = <ChannelModel>[];
      for (var i = 0; i < channels.length; i++) {
        models.add(ChannelModel.fromEntity(channels[i]));
        onProgress?.call(i + 1, total);
      }

      await firebaseDataSource.syncChannels(playlistId, models);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
