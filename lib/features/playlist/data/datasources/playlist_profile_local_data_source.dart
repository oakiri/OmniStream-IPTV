import 'package:hive/hive.dart';
import 'package:omnistream_iptv/features/playlist/data/models/playlist_profile_model.dart';

abstract class PlaylistProfileLocalDataSource {
  Future<void> addPlaylistProfile(PlaylistProfileModel profile);
  Future<void> deletePlaylistProfile(String id);
  Future<List<PlaylistProfileModel>> getPlaylistProfiles();
}

class PlaylistProfileLocalDataSourceImpl implements PlaylistProfileLocalDataSource {
  final Box<PlaylistProfileModel> box;

  PlaylistProfileLocalDataSourceImpl({required this.box});

  @override
  Future<void> addPlaylistProfile(PlaylistProfileModel profile) {
    return box.put(profile.id, profile);
  }

  @override
  Future<void> deletePlaylistProfile(String id) {
    return box.delete(id);
  }

  @override
  Future<List<PlaylistProfileModel>> getPlaylistProfiles() {
    return Future.value(box.values.toList());
  }
}
