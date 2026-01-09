import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Core
import 'package:omnistream_iptv/core/error/failure.dart';

// Auth
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/sign_in_anonymously.dart';

// Playlist
import 'features/playlist/data/datasources/playlist_profile_local_data_source.dart';
import 'features/playlist/data/models/playlist_profile_model.dart';
import 'features/playlist/data/models/channel_model.dart'; 
import 'features/playlist/data/repositories/playlist_profile_repository_impl.dart';
import 'features/playlist/domain/repositories/playlist_profile_repository.dart';
import 'features/playlist/domain/usecases/add_playlist_profile.dart';
import 'features/playlist/domain/usecases/delete_playlist_profile.dart';
import 'features/playlist/domain/usecases/get_playlist_profiles.dart';
import 'features/playlist/presentation/bloc/playlist_profile_bloc.dart';
import 'features/playlist/presentation/bloc/playlist_bloc.dart'; 
import 'features/playlist/domain/usecases/get_playlist.dart';
import 'features/playlist/domain/usecases/toggle_favorite.dart';
import 'features/playlist/domain/repositories/playlist_repository.dart';
import 'features/playlist/data/repositories/playlist_repository_impl.dart';
import 'features/playlist/data/datasources/playlist_local_data_source.dart';
import 'features/playlist/data/datasources/favorite_remote_data_source.dart';
import 'features/playlist/domain/repositories/favorite_repository.dart';
import 'features/playlist/data/repositories/favorite_repository_impl.dart';

// Channels
import 'package:omnistream_iptv/features/channels/data/datasources/channel_remote_data_source.dart';
import 'package:omnistream_iptv/features/channels/data/datasources/firebase_channel_data_source.dart';
import 'package:omnistream_iptv/features/channels/data/repositories/channel_repository_impl.dart';
import 'package:omnistream_iptv/features/channels/domain/repositories/channel_repository.dart';
import 'package:omnistream_iptv/features/channels/domain/usecases/get_channels.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_bloc.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, User?>> signInAnonymously() async => const Right(null);
}

final sl = GetIt.instance;

Future<void> init() async {
  //! External
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseAuth.instance);

  //! Auth
  sl.registerLazySingleton(() => SignInAnonymously(sl()));
  sl.registerLazySingleton<AuthRepository>(() => MockAuthRepository());

  //! Hive - REGISTRO DE ADAPTERS
  // Nota: Si el Adapter no existe aún, comentamos la línea para que compile
  // y luego ejecutamos build_runner para generarlo.
  // Hive.registerAdapter(PlaylistProfileModelAdapter()); 
  
  // Abrimos cajas
  final profileBox = await Hive.openBox<PlaylistProfileModel>('playlist_profiles');
  final channelBox = await Hive.openBox<ChannelModel>('channels');

  //! Data Sources
  sl.registerLazySingleton<PlaylistProfileLocalDataSource>(
    () => PlaylistProfileLocalDataSourceImpl(box: profileBox),
  );
  sl.registerLazySingleton<PlaylistLocalDataSource>(
    () => PlaylistLocalDataSourceImpl(channelBox: channelBox),
  );
  sl.registerLazySingleton<FavoriteRemoteDataSource>(
    () => FavoriteRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<ChannelRemoteDataSource>(
    () => ChannelRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<FirebaseChannelDataSource>(
    () => FirebaseChannelDataSourceImpl(firestore: sl(), auth: sl()),
  );

  //! Repositories
  sl.registerLazySingleton<PlaylistProfileRepository>(
    () => PlaylistProfileRepositoryImpl(
      localDataSource: sl(),
      firebaseAuth: sl(),
      // Eliminados remote y networkInfo
    ),
  );
  sl.registerLazySingleton<PlaylistRepository>(
    () => PlaylistRepositoryImpl(
      localDataSource: sl(),
      // Eliminados remote y networkInfo
    ),
  );
  sl.registerLazySingleton<FavoriteRepository>(
    () => FavoriteRepositoryImpl(
      remoteDataSource: sl(), 
      firebaseAuth: sl(),
    ),
  );
  sl.registerLazySingleton<ChannelRepository>(
    () => ChannelRepositoryImpl(
      remoteDataSource: sl(),
      firebaseDataSource: sl(),
    ),
  );

  //! Use Cases
  sl.registerLazySingleton(() => GetPlaylistProfiles(sl()));
  sl.registerLazySingleton(() => AddPlaylistProfile(sl()));
  sl.registerLazySingleton(() => DeletePlaylistProfile(sl()));
  sl.registerLazySingleton(() => GetPlaylist(sl()));
  sl.registerLazySingleton(() => ToggleFavorite(repository: sl())); 
  sl.registerLazySingleton(() => GetChannels(sl()));

  //! Blocs
  sl.registerFactory(
    () => PlaylistProfileBloc(
      getPlaylistProfiles: sl(),
      addPlaylistProfile: sl(),
      deletePlaylistProfile: sl(),
    ),
  );
  sl.registerFactory(
    () => PlaylistBloc(
      getPlaylist: sl(),
      toggleFavorite: sl(),
    ),
  );
  sl.registerFactory(
    () => ChannelBloc(getChannels: sl()),
  );
}