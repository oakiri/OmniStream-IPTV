import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:omnistream_iptv/core/errors/failures.dart';
import 'package:omnistream_iptv/features/playlist/data/datasources/playlist_profile_local_data_source.dart';
import 'package:omnistream_iptv/features/playlist/data/datasources/playlist_profile_remote_data_source.dart';
import 'package:omnistream_iptv/features/playlist/data/models/playlist_profile_model.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/playlist_profile.dart';
import 'package:omnistream_iptv/features/playlist/domain/repositories/playlist_profile_repository.dart';

class PlaylistProfileRepositoryImpl implements PlaylistProfileRepository {
  final PlaylistProfileLocalDataSource localDataSource;
  final PlaylistProfileRemoteDataSource? remoteDataSource; // Ahora es opcional
  final FirebaseAuth? firebaseAuth; // Ahora es opcional
  final dynamic networkInfo; // Añadido para compatibilidad con inyección (opcional)

  PlaylistProfileRepositoryImpl({
    required this.localDataSource,
    this.remoteDataSource, // Ya no es 'required'
    this.firebaseAuth, // Ya no es 'required'
    this.networkInfo, // Ya no es 'required'
  });

  @override
  Future<Either<Failure, void>> addPlaylistProfile(PlaylistProfile profile) async {
    // Si no hay Auth, usamos un ID genérico local
    final userId = firebaseAuth?.currentUser?.uid ?? 'local_user';

    final profileModel = PlaylistProfileModel(
      id: profile.id,
      name: profile.name,
      url: profile.url,
      lastUpdated: profile.lastUpdated,
      isFavorite: profile.isFavorite,
      userId: userId,
    );

    try {
      // 1. Guardar siempre en local
      await localDataSource.addPlaylistProfile(profileModel);
      
      // 2. Intentar guardar en remoto SOLO si está disponible
      if (remoteDataSource != null && firebaseAuth?.currentUser != null) {
        await remoteDataSource!.addPlaylistProfile(userId, profileModel);
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePlaylistProfile(String id) async {
    final userId = firebaseAuth?.currentUser?.uid ?? 'local_user';

    try {
      await localDataSource.deletePlaylistProfile(id);
      
      if (remoteDataSource != null && firebaseAuth?.currentUser != null) {
        await remoteDataSource!.deletePlaylistProfile(userId, id);
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PlaylistProfile>>> getPlaylistProfiles() async {
    // Intentamos cargar local primero (Modo Offline)
    try {
      final localProfiles = await localDataSource.getPlaylistProfiles();
      
      // Si tenemos datos locales o no hay conexión remota, devolvemos lo local
      if (localProfiles.isNotEmpty || remoteDataSource == null || firebaseAuth?.currentUser == null) {
        return Right(localProfiles);
      }

      // Solo intentamos remoto si todo está configurado
      final userId = firebaseAuth!.currentUser!.uid;
      final remoteProfiles = await remoteDataSource!.getPlaylistProfiles(userId);
      
      // Sincronizar de remoto a local
      for (final profile in remoteProfiles) {
        await localDataSource.addPlaylistProfile(profile);
      }
      return Right(remoteProfiles);
    } catch (e) {
      // Si falla algo, devolvemos error (o podríamos devolver lista vacía)
      return Left(ServerFailure(message: e.toString()));
    }
  }
}