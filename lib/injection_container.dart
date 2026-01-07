import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:get_it/get_it.dart';
import 'package:omnistream_iptv/features/playlist/data/datasources/playlist_local_data_source.dart';
import 'package:omnistream_iptv/features/playlist/data/datasources/playlist_parser.dart';
import 'package:omnistream_iptv/features/playlist/data/models/channel_model.dart';
import 'package:omnistream_iptv/features/playlist/data/repositories/playlist_repository_impl.dart';
import 'package:omnistream_iptv/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:omnistream_iptv/features/playlist/domain/usecases/get_playlist.dart';
import 'package:omnistream_iptv/features/playlist/presentation/bloc/playlist_bloc.dart';
import 'package:omnistream_iptv/features/playlist/presentation/bloc/playlist_profile_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:omnistream_iptv/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:omnistream_iptv/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:omnistream_iptv/features/auth/domain/repositories/auth_repository.dart';
import 'package:omnistream_iptv/features/auth/domain/usecases/sign_in_anonymously.dart';
import 'package:omnistream_iptv/features/playlist/data/datasources/playlist_profile_local_data_source.dart';
import 'package:omnistream_iptv/features/playlist/data/datasources/playlist_profile_remote_data_source.dart';
import 'package:omnistream_iptv/features/playlist/data/models/playlist_profile_model.dart';
import 'package:omnistream_iptv/features/playlist/data/repositories/playlist_profile_repository_impl.dart';
import 'package:omnistream_iptv/features/playlist/domain/repositories/playlist_profile_repository.dart';
import 'package:omnistream_iptv/features/playlist/domain/usecases/add_playlist_profile.dart';
import 'package:omnistream_iptv/features/playlist/domain/usecases/delete_playlist_profile.dart';
import 'package:omnistream_iptv/features/playlist/domain/usecases/get_playlist_profiles.dart';
import 'package:omnistream_iptv/features/playlist/data/datasources/favorite_remote_data_source.dart';
import 'package:omnistream_iptv/features/playlist/domain/repositories/favorite_repository.dart';
import 'package:omnistream_iptv/features/playlist/data/repositories/favorite_repository_impl.dart';
import 'package:omnistream_iptv/features/playlist/domain/usecases/toggle_favorite.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // BLoC
  sl.registerFactory(
    () => PlaylistBloc(
      getPlaylist: sl(),
    ),
  );
  sl.registerFactory(
    () => PlaylistProfileBloc(
      getPlaylistProfiles: sl(),
      addPlaylistProfile: sl(),
      deletePlaylistProfile: sl(),
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

  // Auth
  // Use cases
  sl.registerLazySingleton(() => SignInAnonymously(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(firebaseAuth: sl()),
  );

  // External
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);

  // Playlist Profiles
  // Use cases
  sl.registerLazySingleton(() => AddPlaylistProfile(sl()));
  sl.registerLazySingleton(() => DeletePlaylistProfile(sl()));
  sl.registerLazySingleton(() => GetPlaylistProfiles(sl()));
  sl.registerLazySingleton(() => ToggleFavorite(repository: sl()));

  // Repository
  sl.registerLazySingleton<PlaylistProfileRepository>(
    () => PlaylistProfileRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      firebaseAuth: sl(),
    ),
  );

  sl.registerLazySingleton<FavoriteRepository>(
    () => FavoriteRepositoryImpl(
      remoteDataSource: sl(),
      firebaseAuth: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<PlaylistProfileLocalDataSource>(
    () => PlaylistProfileLocalDataSourceImpl(box: sl()),
  );
  sl.registerLazySingleton<PlaylistProfileRemoteDataSource>(
    () => PlaylistProfileRemoteDataSourceImpl(firestore: sl()),
  );

  sl.registerLazySingleton<FavoriteRemoteDataSource>(
    () => FavoriteRemoteDataSourceImpl(firestore: sl()),
  );

  sl.registerLazySingleton<Box<PlaylistProfileModel>>(
    () => Hive.box<PlaylistProfileModel>('playlist_profiles'),
  );
}
