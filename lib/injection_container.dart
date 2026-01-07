import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart'; // IMPORTANTE: Necesario para el tipo User
import 'package:omnistream_iptv/core/errors/failures.dart'; // CORREGIDO: errors (plural)

import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/sign_in_anonymously.dart';
import 'features/playlist/data/datasources/playlist_profile_local_data_source.dart';
import 'features/playlist/data/models/playlist_profile_model.dart';
import 'features/playlist/data/repositories/playlist_profile_repository_impl.dart';
import 'features/playlist/domain/repositories/playlist_profile_repository.dart';
import 'features/playlist/domain/usecases/add_playlist_profile.dart';
import 'features/playlist/domain/usecases/delete_playlist_profile.dart';
import 'features/playlist/domain/usecases/get_playlist_profiles.dart';
import 'features/playlist/presentation/bloc/playlist_profile_bloc.dart';

// MOCK CORREGIDO
class MockAuthRepository implements AuthRepository {
  @override
  // Ahora devuelve el tipo exacto que espera la interfaz: User?
  Future<Either<Failure, User?>> signInAnonymously() async => const Right(null);
}

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Playlist Profiles (Hive)
  sl.registerFactory(
    () => PlaylistProfileBloc(
      getPlaylistProfiles: sl(),
      addPlaylistProfile: sl(),
      deletePlaylistProfile: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetPlaylistProfiles(sl()));
  sl.registerLazySingleton(() => AddPlaylistProfile(sl()));
  sl.registerLazySingleton(() => DeletePlaylistProfile(sl()));

  // Repositorio en modo LOCAL (remoteDataSource es null)
  sl.registerLazySingleton<PlaylistProfileRepository>(
    () => PlaylistProfileRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: null,
      firebaseAuth: null, 
      networkInfo: null,
    ),
  );

  if (!Hive.isAdapterRegistered(1)) {
     Hive.registerAdapter(PlaylistProfileModelAdapter());
  }
  final profileBox = await Hive.openBox<PlaylistProfileModel>('playlist_profiles');
  
  sl.registerLazySingleton<PlaylistProfileLocalDataSource>(
    () => PlaylistProfileLocalDataSourceImpl(box: profileBox),
  );

  //! Features - Auth
  sl.registerLazySingleton(() => SignInAnonymously(sl()));
  sl.registerLazySingleton<AuthRepository>(() => MockAuthRepository());

  //! External
  sl.registerLazySingleton(() => http.Client());
}