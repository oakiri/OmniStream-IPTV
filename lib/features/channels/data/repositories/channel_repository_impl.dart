import 'package:dartz/dartz.dart';
import 'package:omnistream_iptv/core/error/failure.dart';
import 'package:omnistream_iptv/core/utils/m3u_parser.dart';
import 'package:omnistream_iptv/features/channels/data/datasources/channel_remote_data_source.dart';
import 'package:omnistream_iptv/features/channels/data/datasources/firebase_channel_data_source.dart';
import 'package:omnistream_iptv/features/channels/domain/repositories/channel_repository.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';
import 'package:omnistream_iptv/features/playlist/data/models/channel_model.dart';

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
  Future<Either<Failure, void>> syncWithFirestore(String playlistId, List<Channel> channels, {Function(int, int)? onProgress}) async {
    try {
      final models = channels.map((c) => ChannelModel.fromEntity(c)).toList();
      await firebaseDataSource.syncChannels(playlistId, models);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Channel>>> getChannelsPaginated(String playlistId, {int limit = 50}) async {
    return const Right([]);
  }
}