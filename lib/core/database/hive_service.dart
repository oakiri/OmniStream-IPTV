import 'package:hive_flutter/hive_flutter.dart';

import '../../features/playlist/data/models/playlist_profile_model.dart';

class HiveService {
  static const String playlistProfilesBox = 'playlist_profiles';

  Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(PlaylistProfileModelAdapter().typeId)) {
      Hive.registerAdapter(PlaylistProfileModelAdapter());
    }

    if (!Hive.isBoxOpen(playlistProfilesBox)) {
      await Hive.openBox<PlaylistProfileModel>(playlistProfilesBox);
    }
  }

  Box<PlaylistProfileModel> get playlistProfiles =>
      Hive.box<PlaylistProfileModel>(playlistProfilesBox);
}
