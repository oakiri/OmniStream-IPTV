import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import 'core/database/hive_service.dart';
import 'features/channels/data/datasources/channel_remote_data_source.dart';
import 'features/channels/data/datasources/firebase_channel_data_source.dart';
import 'features/channels/data/repositories/channel_repository_impl.dart';
import 'features/channels/domain/repositories/channel_repository.dart';
import 'features/channels/domain/usecases/get_channels.dart';
import 'features/channels/presentation/bloc/channel_bloc.dart';
import 'features/playlist/data/datasources/favorite_remote_data_source.dart';
import 'features/playlist/data/datasources/playlist_local_data_source.dart';
import 'features/playlist/data/datasources/playlist_profile_local_data_source.dart';
import 'features/playlist/data/datasources/playlist_profile_remote_data_source.dart';
import 'features/playlist/data/models/playlist_profile_model.dart';
import 'features/playlist/data/repositories/favorite_repository_impl.dart';
import 'features/playlist/data/repositories/playlist_profile_repository_impl.dart';
import 'features/playlist/data/repositories/playlist_repository_impl.dart';
import 'features/playlist/domain/repositories/favorite_repository.dart';
import 'features/playlist/domain/repositories/playlist_profile_repository.dart';
import 'features/playlist/domain/repositories/playlist_repository.dart';
import 'features/playlist/domain/usecases/add_playlist_profile.dart';
import 'features/playlist/domain/usecases/delete_playlist_profile.dart';
import 'features/playlist/domain/usecases/get_playlist.dart';
import 'features/playlist/domain/usecases/get_playlist_profiles.dart';
import 'features/playlist/domain/usecases/toggle_favorite.dart';
import 'features/playlist/presentation/bloc/playlist_bloc.dart';
import 'features/playlist/presentation/bloc/playlist_profile_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Firebase
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // Hive
  sl.registerLazySingleton<HiveService>(() => HiveService());
  await sl<HiveService>().init();

  sl.registerLazySingleton<Box<PlaylistProfileModel>>(
    () => sl<HiveService>().playlistProfiles,
  );

  // DataSources
  sl.registerLazySingleton<PlaylistLocalDataSource>(
    () => PlaylistLocalDataSourceImpl(),
  );

  sl.registerLazySingleton<FavoriteRemoteDataSource>(
    () => FavoriteRemoteDataSourceImpl(),
  );

  sl.registerLazySingleton<PlaylistProfileLocalDataSource>(
    () => PlaylistProfileLocalDataSourceImpl(
        box: sl<Box<PlaylistProfileModel>>()),
  );

  sl.registerLazySingleton<PlaylistProfileRemoteDataSource>(
    () =>
        PlaylistProfileRemoteDataSourceImpl(firestore: sl<FirebaseFirestore>()),
  );

  sl.registerLazySingleton<ChannelRemoteDataSource>(
    () => ChannelRemoteDataSourceImpl(),
  );

  sl.registerLazySingleton<FirebaseChannelDataSource>(
    () => FirebaseChannelDataSourceImpl(firestore: sl<FirebaseFirestore>()),
  );

  // Repositories
  sl.registerLazySingleton<PlaylistRepository>(
    () => PlaylistRepositoryImpl(
      localDataSource: sl<PlaylistLocalDataSource>(),
    ),
  );

  sl.registerLazySingleton<FavoriteRepository>(
    () => FavoriteRepositoryImpl(
      remoteDataSource: sl<FavoriteRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton<PlaylistProfileRepository>(
    () => PlaylistProfileRepositoryImpl(
      localDataSource: sl<PlaylistProfileLocalDataSource>(),
      remoteDataSource: sl<PlaylistProfileRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton<ChannelRepository>(
    () => ChannelRepositoryImpl(
      remoteDataSource: sl<ChannelRemoteDataSource>(),
      firebaseDataSource: sl<FirebaseChannelDataSource>(),
    ),
  );

  // UseCases
  sl.registerLazySingleton(() => GetPlaylist(sl<PlaylistRepository>()));
  sl.registerLazySingleton(() => ToggleFavorite(sl<FavoriteRepository>()));
  sl.registerLazySingleton(
      () => GetPlaylistProfiles(sl<PlaylistProfileRepository>()));
  sl.registerLazySingleton(
      () => AddPlaylistProfile(sl<PlaylistProfileRepository>()));
  sl.registerLazySingleton(
      () => DeletePlaylistProfile(sl<PlaylistProfileRepository>()));

  sl.registerLazySingleton(() => GetChannels(sl<ChannelRepository>()));

  // Blocs
  sl.registerFactory(
    () => PlaylistBloc(
      getPlaylist: sl<GetPlaylist>(),
      toggleFavorite: sl<ToggleFavorite>(),
    ),
  );

// PLAYLIST PROFILE - DataSources
  sl.registerLazySingleton<PlaylistProfileLocalDataSource>(
    () => PlaylistProfileLocalDataSourceImpl(box: sl()),
  );

  sl.registerLazySingleton<PlaylistProfileRemoteDataSource>(
    () => PlaylistProfileRemoteDataSourceImpl(firestore: sl()),
  );

// PLAYLIST PROFILE - Repository
  sl.registerLazySingleton<PlaylistProfileRepository>(
    () => PlaylistProfileRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      firebaseAuth: sl(),
    ),
  );

  sl.registerFactory(
    () => ChannelBloc(getChannels: sl<GetChannels>()),
  );
}
