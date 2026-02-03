import 'package:dartz/dartz.dart';
import 'package:omnistream_iptv/core/error/failure.dart';
import 'package:omnistream_iptv/core/utils/m3u_parser.dart';
import 'package:omnistream_iptv/features/playlist/data/datasources/playlist_local_data_source.dart';
import 'package:omnistream_iptv/features/playlist/data/models/channel_model.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';
import 'package:omnistream_iptv/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:http/http.dart' as http;

class PlaylistRepositoryImpl implements PlaylistRepository {
  final PlaylistLocalDataSource localDataSource;
  // Eliminado NetworkInfo

  PlaylistRepositoryImpl({
    required this.localDataSource,
  });

  // RENOMBRADO de getPlaylist a getChannels para cumplir con la interfaz
  @override
  Future<Either<Failure, List<Channel>>> getChannels(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final channels = M3uParser.parse(response.body);
        
        final channelModels = channels.map((c) => ChannelModel(
          id: c.id,
          name: c.name,
          url: c.url,
          logoUrl: c.logoUrl,
          group: c.group,
        )).toList();
        
        await localDataSource.cacheChannels(channelModels);
        
        return Right(channels);
      } else {
        return Left(ServerFailure(message: 'Error ${response.statusCode}'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to load playlist: $e'));
    }
  }
}