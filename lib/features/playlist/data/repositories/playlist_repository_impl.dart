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
  
  // Limit to prevent app crash with massive playlists
  static const int MAX_CHANNELS = 5000;

  PlaylistRepositoryImpl({
    required this.dio,
    required this.parser,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<Channel>>> getChannels(String url) async {
    try {
      print('[PlaylistRepository] Descargando desde: $url');
      final response = await dio.get(url);
      print('[PlaylistRepository] Respuesta recibida: ${response.statusCode}');
      final content = response.data.toString();
      print('[PlaylistRepository] Tamaño del contenido: ${content.length} bytes');

      // Use compute to run parsing in a separate isolate.
      // Parser returns List<Channel> entities
      print('[PlaylistRepository] Iniciando parsing en Isolate...');
      var channels = await compute(parser.parse, content);
      print('[PlaylistRepository] Parsing completado: ${channels.length} canales');

      // OPTIMIZATION: Limit to MAX_CHANNELS to prevent app crash
      if (channels.length > MAX_CHANNELS) {
        print('[PlaylistRepository] ⚠ Playlist tiene ${channels.length} canales. Limitando a $MAX_CHANNELS');
        channels = channels.sublist(0, MAX_CHANNELS);
        print('[PlaylistRepository] ✓ Limitado a $MAX_CHANNELS canales');
      }

      // Convert Channel entities to ChannelModel for caching
      print('[PlaylistRepository] Convirtiendo a modelos para caché...');
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
      print('[PlaylistRepository] Guardando en caché local ${channelModels.length} canales...');
      await localDataSource.cacheChannels(channelModels);
      print('[PlaylistRepository] Caché guardado exitosamente');

      // Return the Channel entities
      return Right(channels);
    } catch (e) {
      // Handle exceptions, e.g., network errors, parsing errors
      print('[PlaylistRepository] Error cargando canales: $e');
      return Left(ServerFailure('Failed to load or parse playlist: $e'));
    }
  }
}
