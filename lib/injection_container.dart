import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:omnistream_iptv/features/playlist/data/datasources/playlist_local_data_source.dart';
import 'package:omnistream_iptv/features/playlist/data/datasources/playlist_parser.dart';
import 'package:omnistream_iptv/features/playlist/data/models/channel_model.dart';
import 'package:omnistream_iptv/features/playlist/data/repositories/playlist_repository_impl.dart';
import 'package:omnistream_iptv/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:omnistream_iptv/features/playlist/domain/usecases/get_playlist.dart';
import 'package:omnistream_iptv/features/playlist/presentation/bloc/playlist_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // BLoC
  sl.registerFactory(
    () => PlaylistBloc(
      getPlaylist: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetPlaylist(sl()));

  // Repository
  sl.registerLazySingleton<PlaylistRepository>(
    () => PlaylistRepositoryImpl(
      dio: sl(),
      parser: sl(),
      localDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<PlaylistLocalDataSource>(
    () => PlaylistLocalDataSourceImpl(channelBox: sl()),
  );
  sl.registerLazySingleton(() => PlaylistParser());

  // External - Dio with certificate bypass for IPTV providers
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio();
    
    // Configure to accept insecure certificates (required for many IPTV providers)
    try {
      print('[DI] Configuring Dio with insecure certificate bypass...');
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          print('[DI] Certificate verification bypassed for: $host:$port');
          return true; // Accept all certificates
        };
        return client;
      };
      print('✓ [DI] Dio configured successfully');
    } catch (e) {
      print('⚠ [DI] Warning: Could not configure certificate bypass: $e');
    }
    
    return dio;
  });
  
  sl.registerLazySingleton<Box<ChannelModel>>(() => Hive.box<ChannelModel>('channels'));
}
