import 'package:hive/hive.dart';
import 'package:omnistream_iptv/features/playlist/data/models/playlist_profile_model.dart';

abstract class PlaylistProfileLocalDataSource {
  Future<void> addPlaylistProfile(PlaylistProfileModel profile);
  Future<void> deletePlaylistProfile(String id);
  Future<List<PlaylistProfileModel>> getPlaylistProfiles();
  
  // Métodos que faltaban y causaban error
  Future<void> cachePlaylistProfile(PlaylistProfileModel profile);
  Future<List<PlaylistProfileModel>> getLastPlaylistProfiles();
}

class PlaylistProfileLocalDataSourceImpl implements PlaylistProfileLocalDataSource {
  final Box<PlaylistProfileModel> box;

  PlaylistProfileLocalDataSourceImpl({required this.box});

  @override
  Future<void> addPlaylistProfile(PlaylistProfileModel profile) => box.put(profile.id, profile);

  @override
  Future<void> deletePlaylistProfile(String id) => box.delete(id);

  @override
  Future<List<PlaylistProfileModel>> getPlaylistProfiles() async => box.values.toList();

  // Implementación de los métodos faltantes (reutilizando lógica)
  @override
  Future<void> cachePlaylistProfile(PlaylistProfileModel profile) => addPlaylistProfile(profile);

  @override
  Future<List<PlaylistProfileModel>> getLastPlaylistProfiles() => getPlaylistProfiles();
}