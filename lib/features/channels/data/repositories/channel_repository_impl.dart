import 'package:dartz/dartz.dart';
import 'package:omnistream_iptv/core/errors/failures.dart';
import 'package:omnistream_iptv/core/errors/exceptions.dart';
import 'package:omnistream_iptv/core/utils/m3u_parser.dart';
import 'package:omnistream_iptv/features/channels/data/datasources/channel_remote_data_source.dart';
import 'package:omnistream_iptv/features/channels/domain/entities/channel.dart';
import 'package:omnistream_iptv/features/channels/domain/repositories/channel_repository.dart';

class ChannelRepositoryImpl implements ChannelRepository {
  final ChannelRemoteDataSource remoteDataSource;

  ChannelRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Channel>>> getChannels(String url) async {
    try {
      final m3uContent = await remoteDataSource.getM3UContent(url);
      final channels = await M3UParser.parse(m3uContent);
      return Right(channels);
    } on ServerException {
      return Left(ServerFailure(message: 'Failed to fetch channels'));
    }
  }
}
