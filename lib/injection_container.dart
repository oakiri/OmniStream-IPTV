import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:omnistream_iptv/core/utils/m3u_parser.dart';

// Features - Playlist Profiles (Gestión de Listas y Borrado)
import 'features/playlist/data/datasources/playlist_profile_local_data_source.dart';
import 'features/playlist/data/models/playlist_profile_model.dart';
import 'features/playlist/data/repositories/playlist_profile_repository_impl.dart';
import 'features/playlist/domain/repositories/playlist_profile_repository.dart';
import 'features/playlist/domain/usecases/add_playlist_profile.dart';
import 'features/playlist/domain/usecases/get_playlist_profiles.dart';
import 'features/playlist/domain/usecases/delete_playlist_profile.dart';
import 'features/playlist/presentation/bloc/playlist_profile_bloc.dart';

// Features - Channels (Canales y Reproducción)
import 'features/channels/data/datasources/channel_remote_data_source.dart';
import 'features/channels/data/datasources/firebase_channel_data_source.dart'; // Importante
import 'features/channels/data/repositories/channel_repository_impl.dart';
import 'features/channels/domain/repositories/channel_repository.dart';
import 'features/channels/domain/usecases/get_channels.dart';
import 'features/channels/presentation/bloc/channel_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ! Features - Playlist Profiles
  // Bloc
  sl.registerFactory(
    () => PlaylistProfileBloc(
      getPlaylistProfiles: sl(),
      addPlaylistProfile: sl(),
      deletePlaylistProfile: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetPlaylistProfiles(sl()));
  sl.registerLazySingleton(() => AddPlaylistProfile(sl()));
  sl.registerLazySingleton(() => DeletePlaylistProfile(sl()));

  // Repository
  sl.registerLazySingleton<PlaylistProfileRepository>(
    () => PlaylistProfileRepositoryImpl(
      localDataSource: sl(),
      firestore: sl(),
      firebaseAuth: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<PlaylistProfileLocalDataSource>(
    () => PlaylistProfileLocalDataSourceImpl(box: sl()),
  );

  // ! Features - Channels
  // Bloc
  sl.registerFactory(() => ChannelBloc(getChannels: sl()));

  // Use cases
  sl.registerLazySingleton(() => GetChannels(sl()));

  // Repository
  // CORRECCIÓN DEL LOG: Ahora inyectamos también el firebaseDataSource
  sl.registerLazySingleton<ChannelRepository>(
    () => ChannelRepositoryImpl(
      remoteDataSource: sl(),
      firebaseDataSource: sl(), 
    ),
  );

  // Data sources
  // CORRECCIÓN DEL LOG: Quitamos m3uParser porque el constructor ya no lo pide
  sl.registerLazySingleton<ChannelRemoteDataSource>(
    () => ChannelRemoteDataSourceImpl(client: sl()),
  );

  // Nuevo DataSource de Firebase para Canales
  sl.registerLazySingleton<FirebaseChannelDataSource>(
    () => FirebaseChannelDataSourceImpl(
      firestore: sl(),
      auth: sl(),
    ),
  );

  // ! Core
  sl.registerLazySingleton(() => M3uParser());

  // ! External
  final profileBox = await Hive.openBox<PlaylistProfileModel>('playlist_profiles');
  sl.registerLazySingleton(() => profileBox);

  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseAuth.instance);
}