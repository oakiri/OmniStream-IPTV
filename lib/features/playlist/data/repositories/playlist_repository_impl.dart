import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:omnistream_iptv/features/playlist/data/datasources/playlist_parser.dart';
import 'package:omnistream_iptv/features/playlist/data/models/channel_model.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';
import 'package:omnistream_iptv/features/playlist/domain/repositories/playlist_repository.dart';

class PlaylistRepositoryImpl implements PlaylistRepository {
  final Dio dio;
  final PlaylistParser parser;

  PlaylistRepositoryImpl({required this.dio, required this.parser});

  @override
  Future<List<Channel>> getChannels(String url) async {
    try {
      final response = await dio.get(url);
      final content = response.data.toString();

      // Use compute to run parsing in a separate isolate.
      final channels = await compute(parser.parse, content);

      return channels;
    } catch (e) {
      // Handle exceptions, e.g., network errors, parsing errors
      throw Exception('Failed to load or parse playlist: $e');
    }
  }
}
