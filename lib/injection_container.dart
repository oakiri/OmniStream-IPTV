import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import 'core/database/hive_service.dart';

// AUTH
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/sign_in_anonymously.dart';

// CHANNELS
import 'features/channels/data/datasources/channel_remote_data_source.dart';
import 'features/channels/data/datasources/firebase_channel_data_source.dart';
import 'features/channels/data/repositories/channel_repository_impl.dart';
import 'features/channels/domain/repositories/channel_repository.dart';
import 'features/channels/domain/usecases/get_channels.dart';
import 'features/channels/presentation/bloc/channel_bloc.dart';

// PLAYLIST
import 'features/playlist/data/datasources/favorite_remote_data_source.dart';
import 'features/playlist/data/datasources/playlist_local_data_source.dart';
import 'features/playlist/data/datasources/playlist_profile_local_data_source.dart';
import 'features/playlist/data/datasources/playlist_profile_remote_data_source.dart';
import 'features/playlist/data/models/channel_model.dart';
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
  // =========================
  // EXTERNAL
  // =========================
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<http.Client>(() => http.Client());

  // =========================
  // HIVE
  // =========================
  sl.registerLazySingleton<HiveService>(() => HiveService());

  // Boxes (exponen getters en HiveService)
  sl.registerLazySingleton<Box<PlaylistProfileModel>>(
    () => sl<HiveService>().playlistProfiles,
  );

  sl.registerLazySingleton<Box<ChannelModel>>(
    () => sl<HiveService>().channelBox,
  );

  // =========================
  // DATASOURCES
  // =========================

  // AUTH
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(firebaseAuth: sl<FirebaseAuth>()),
  );

  // CHANNELS
  sl.registerLazySingleton<ChannelRemoteDataSource>(
    () => ChannelRemoteDataSourceImpl(client: sl<http.Client>()),
  );

  sl.registerLazySingleton<FirebaseChannelDataSource>(
    () => FirebaseChannelDataSourceImpl(
      firestore: sl<FirebaseFirestore>(),
      auth: sl<FirebaseAuth>(),
    ),
  );

  // PLAYLIST
  sl.registerLazySingleton<PlaylistLocalDataSource>(
    () => PlaylistLocalDataSourceImpl(
      channelBox: sl<Box<ChannelModel>>(),
    ),
  );

  sl.registerLazySingleton<FavoriteRemoteDataSource>(
    () => FavoriteRemoteDataSourceImpl(
      firestore: sl<FirebaseFirestore>(),
    ),
  );

  sl.registerLazySingleton<PlaylistProfileLocalDataSource>(
    () => PlaylistProfileLocalDataSourceImpl(
      box: sl<Box<PlaylistProfileModel>>(),
    ),
  );

  sl.registerLazySingleton<PlaylistProfileRemoteDataSource>(
    () => PlaylistProfileRemoteDataSourceImpl(
      firestore: sl<FirebaseFirestore>(),
    ),
  );

  // =========================
  // REPOSITORIES
  // =========================

  // AUTH
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl<AuthRemoteDataSource>()),
  );

  // CHANNELS
  sl.registerLazySingleton<ChannelRepository>(
    () => ChannelRepositoryImpl(
      remoteDataSource: sl<ChannelRemoteDataSource>(),
      firebaseDataSource: sl<FirebaseChannelDataSource>(),
    ),
  );

  // PLAYLIST
  sl.registerLazySingleton<PlaylistRepository>(
    () => PlaylistRepositoryImpl(
      localDataSource: sl<PlaylistLocalDataSource>(),
    ),
  );

  sl.registerLazySingleton<FavoriteRepository>(
    () => FavoriteRepositoryImpl(
      remoteDataSource: sl<FavoriteRemoteDataSource>(),
      firebaseAuth: sl<FirebaseAuth>(),
    ),
  );

  sl.registerLazySingleton<PlaylistProfileRepository>(
    () => PlaylistProfileRepositoryImpl(
      localDataSource: sl<PlaylistProfileLocalDataSource>(),
      remoteDataSource: sl<PlaylistProfileRemoteDataSource>(),
      firebaseAuth: sl<FirebaseAuth>(),
    ),
  );

  // =========================
  // USECASES
  // =========================

  // AUTH
  sl.registerLazySingleton(() => SignInAnonymously(sl<AuthRepository>()));

  // CHANNELS
  sl.registerLazySingleton(() => GetChannels(sl<ChannelRepository>()));

  // PLAYLIST
  sl.registerLazySingleton(() => GetPlaylist(sl<PlaylistRepository>()));
  sl.registerLazySingleton(() => ToggleFavorite(repository: sl<FavoriteRepository>()));

  sl.registerLazySingleton(
    () => GetPlaylistProfiles(sl<PlaylistProfileRepository>()),
  );
  sl.registerLazySingleton(
    () => AddPlaylistProfile(sl<PlaylistProfileRepository>()),
  );
  sl.registerLazySingleton(
    () => DeletePlaylistProfile(sl<PlaylistProfileRepository>()),
  );

  // =========================
  // BLOCS
  // =========================

  sl.registerFactory(
    () => ChannelBloc(getChannels: sl<GetChannels>()),
  );

  sl.registerFactory(
    () => PlaylistBloc(
      sl<GetPlaylist>(),
      sl<ToggleFavorite>(),
    ),
  );

  sl.registerFactory(
    () => PlaylistProfileBloc(
      addPlaylistProfile: sl<AddPlaylistProfile>(),
      deletePlaylistProfile: sl<DeletePlaylistProfile>(),
      getPlaylistProfiles: sl<GetPlaylistProfiles>(),
    ),
  );
}
