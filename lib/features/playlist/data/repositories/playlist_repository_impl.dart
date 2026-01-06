import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:omnistream_iptv/features/playlist/data/datasources/playlist_parser.dart';
import 'package:omnistream_iptv/features/playlist/data/models/channel_model.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';
import 'package:omnistream_iptv/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:omnistream_iptv/features/playlist/data/datasources/playlist_local_data_source.dart';
import 'package:omnistream_iptv/core/error/failure.dart';
import 'package:dartz/dartz.dart';

class PlaylistRepositoryImpl implements PlaylistRepository {
  final Dio dio;
  final PlaylistParser parser;
  final PlaylistLocalDataSource localDataSource;

  PlaylistRepositoryImpl({
    required this.dio,
    required this.parser,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<Channel>>> getChannels(String url) async {
    try {
      final response = await dio.get(url);
      final content = response.data.toString();

      // Use compute to run parsing in a separate isolate.
      // Parser returns List<Channel> entities
      final channels = await compute(parser.parse, content);

      // Convert Channel entities to ChannelModel for caching
      final channelModels = channels
          .map((channel) => ChannelModel(
                id: channel.id,
                name: channel.name,
                url: channel.url,
                group: channel.group,
                logoUrl: channel.logoUrl,
              ))
          .toList();

      // Cache the channel models
      await localDataSource.cacheChannels(channelModels);

      // Return the Channel entities
      return Right(channels);
    } catch (e) {
      // Handle exceptions, e.g., network errors, parsing errors
      return Left(ServerFailure('Failed to load or parse playlist: $e'));
    }
  }
}
