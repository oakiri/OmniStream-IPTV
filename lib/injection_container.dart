import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:hive/hive.dart';

// Features - Auth
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/sign_in_anonymously.dart';

// Features - Playlist (Core & Profiles)
import 'features/playlist/data/datasources/playlist_local_data_source.dart';
import 'features/playlist/data/datasources/playlist_profile_local_data_source.dart';
import 'features/playlist/data/datasources/playlist_parser.dart';
import 'features/playlist/data/repositories/playlist_repository_impl.dart';
import 'features/playlist/data/repositories/playlist_profile_repository_impl.dart';
import 'features/playlist/domain/repositories/playlist_repository.dart';
import 'features/playlist/domain/repositories/playlist_profile_repository.dart';
import 'features/playlist/domain/usecases/get_playlist.dart';
import 'features/playlist/domain/usecases/get_playlist_profiles.dart';
import 'features/playlist/domain/usecases/add_playlist_profile.dart';
import 'features/playlist/domain/usecases/update_playlist_profile.dart';
import 'features/playlist/domain/usecases/delete_playlist_profile.dart';
import 'features/playlist/presentation/bloc/playlist_bloc.dart';
import 'features/playlist/presentation/bloc/playlist_profile_bloc.dart';
import 'features/playlist/data/models/playlist_profile_model.dart';
import 'features/playlist/data/models/channel_model.dart';

// Features - Playlist (Favorites) - ¡ESTOS FALTABAN!
import 'features/playlist/data/datasources/favorite_remote_data_source.dart';
import 'features/playlist/data/repositories/favorite_repository_impl.dart';
import 'features/playlist/domain/repositories/favorite_repository.dart';
import 'features/playlist/domain/usecases/toggle_favorite.dart';

// Features - Channels
import 'features/channels/data/datasources/channel_remote_data_source.dart';
import 'features/channels/data/datasources/firebase_channel_data_source.dart';
import 'features/channels/data/repositories/channel_repository_impl.dart';
import 'features/channels/domain/repositories/channel_repository.dart';
import 'features/channels/domain/usecases/get_channels.dart';
import 'features/channels/presentation/bloc/channel_bloc.dart';

// Core
import 'core/utils/m3u_parser.dart';
import 'core/storage/recent_playback_store.dart';

// EPG
import 'core/epg/epg_settings_store.dart';
import 'core/epg/epg_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Playlist Profile
  // Bloc
  sl.registerFactory(() => PlaylistProfileBloc(
    getPlaylistProfiles: sl(),
    addPlaylistProfile: sl(),
    updatePlaylistProfile: sl(),
    deletePlaylistProfile: sl(),
  ));

  // Use cases
  sl.registerLazySingleton(() => GetPlaylistProfiles(sl()));
  sl.registerLazySingleton(() => AddPlaylistProfile(sl()));
  sl.registerLazySingleton(() => UpdatePlaylistProfile(sl()));
  sl.registerLazySingleton(() => DeletePlaylistProfile(sl()));

  // Repository
  sl.registerLazySingleton<PlaylistProfileRepository>(
    () => PlaylistProfileRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<PlaylistProfileLocalDataSource>(
    () => PlaylistProfileLocalDataSourceImpl(box: sl()),
  );

  //! Features - Playlist (Parser, Favorites & Content)
  // Bloc
  sl.registerFactory(() => PlaylistBloc(
    getPlaylist: sl(),
    toggleFavorite: sl(),
  ));

  // Use cases
  sl.registerLazySingleton(() => GetPlaylist(sl()));
  
  // CORRECCIÓN: Usamos parámetro nombrado 'repository'
  sl.registerLazySingleton(() => ToggleFavorite(repository: sl())); 

  // Repositories
  sl.registerLazySingleton<PlaylistRepository>(
    () => PlaylistRepositoryImpl(
      localDataSource: sl(),
    ),
  );

  // REGISTRO DE FAVORITOS (Esto faltaba y hubiera dado error después)
  sl.registerLazySingleton<FavoriteRepository>(
    () => FavoriteRepositoryImpl(
      remoteDataSource: sl(),
      firebaseAuth: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<PlaylistLocalDataSource>(
    () => PlaylistLocalDataSourceImpl(channelBox: sl()),
  );
  sl.registerLazySingleton(() => PlaylistParser());

  // REGISTRO DE DATASOURCE FAVORITOS
  sl.registerLazySingleton<FavoriteRemoteDataSource>(
    () => FavoriteRemoteDataSourceImpl(firestore: sl()),
  );

  //! Features - Channels (Nuevo sistema)
  // Bloc
  sl.registerFactory(() => ChannelBloc(getChannels: sl()));

  // Use cases
  sl.registerLazySingleton(() => GetChannels(sl()));

  // Repository
  sl.registerLazySingleton<ChannelRepository>(
    () => ChannelRepositoryImpl(
      remoteDataSource: sl(),
      firebaseDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<ChannelRemoteDataSource>(
    () => ChannelRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<FirebaseChannelDataSource>(
    () => FirebaseChannelDataSourceImpl(
      firestore: sl(),
      auth: sl(),
    ),
  );

  //! Features - Auth
  sl.registerLazySingleton(() => SignInAnonymously(sl()));
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(firebaseAuth: sl()),
  );

  //! Core
  sl.registerLazySingleton(() => M3uParser());

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // EPG (AUTO/Override + fallback por país)
  sl.registerLazySingleton<EpgSettingsStore>(() => EpgSettingsStore(prefs: sl()));
  sl.registerLazySingleton<EpgService>(() => EpgService(client: sl(), settingsStore: sl()));

  // Persistencia UX premium: último canal visto (Continuar viendo)
  sl.registerLazySingleton<RecentPlaybackStore>(() => RecentPlaybackStore(prefs: sl()));

  // Hive Boxes
  final profileBox = await Hive.openBox<PlaylistProfileModel>('playlist_profiles');
  sl.registerLazySingleton<Box<PlaylistProfileModel>>(() => profileBox);

  final channelBox = await Hive.openBox<ChannelModel>('channels');
  sl.registerLazySingleton<Box<ChannelModel>>(() => channelBox);

  // Cliente HTTP (Soporte SSL inseguro)
  sl.registerLazySingleton<http.Client>(() {
    final ioClient = HttpClient();
    // Seguridad: permitir certificados inválidos SOLO en debug.
    ioClient.badCertificateCallback = (X509Certificate cert, String host, int port) => kDebugMode;
    return IOClient(ioClient);
  });

  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => InternetConnectionChecker());
}