import 'package:hive_flutter/hive_flutter.dart';

import '../../features/playlist/data/models/channel_model.dart';
import '../../features/playlist/data/models/playlist_profile_model.dart';

class HiveService {
  static const String playlistProfilesBox = 'playlist_profiles';
  static const String channelsBox = 'channels_cache';

  Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(ChannelModelAdapter().typeId)) {
      Hive.registerAdapter(ChannelModelAdapter());
    }

    if (!Hive.isAdapterRegistered(PlaylistProfileModelAdapter().typeId)) {
      Hive.registerAdapter(PlaylistProfileModelAdapter());
    }

    if (!Hive.isBoxOpen(channelsBox)) {
      await Hive.openBox<ChannelModel>(channelsBox);
    }

    if (!Hive.isBoxOpen(playlistProfilesBox)) {
      await Hive.openBox<PlaylistProfileModel>(playlistProfilesBox);
    }
  }

  Box<ChannelModel> get channelBox => Hive.box<ChannelModel>(channelsBox);

  Box<PlaylistProfileModel> get playlistProfiles =>
      Hive.box<PlaylistProfileModel>(playlistProfilesBox);
}
