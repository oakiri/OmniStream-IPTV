import 'package:hive/hive.dart';
import '../models/playlist_profile_model.dart';

abstract class PlaylistProfileLocalDataSource {
  Future<List<PlaylistProfileModel>> getPlaylistProfiles();
  Future<void> savePlaylistProfile(PlaylistProfileModel profile);
  Future<void> deletePlaylistProfile(String id);
}

class PlaylistProfileLocalDataSourceImpl implements PlaylistProfileLocalDataSource {
  final Box<PlaylistProfileModel> box;

  PlaylistProfileLocalDataSourceImpl({required this.box});

  @override
  Future<List<PlaylistProfileModel>> getPlaylistProfiles() async {
    return box.values.toList();
  }

  @override
  Future<void> savePlaylistProfile(PlaylistProfileModel profile) async {
    await box.put(profile.id, profile);
  }

  @override
  Future<void> deletePlaylistProfile(String id) async {
    await box.delete(id);
  }
}