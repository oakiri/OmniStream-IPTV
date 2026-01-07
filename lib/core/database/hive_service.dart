import 'package:hive_flutter/hive_flutter.dart';
import 'package:omnistream_iptv/features/playlist/data/models/channel_model.dart';
import 'package:omnistream_iptv/features/playlist/data/models/category_model.dart';
import 'package:omnistream_iptv/features/playlist/data/models/epg_program_model.dart';
import 'package:omnistream_iptv/features/playlist/data/models/playlist_profile_model.dart';

class HiveService {
  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ChannelModelAdapter());
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(EPGProgramModelAdapter());
    Hive.registerAdapter(PlaylistProfileModelAdapter());

    await Hive.openBox<ChannelModel>('channels');
    await Hive.openBox<PlaylistProfileModel>('playlist_profiles');
    await Hive.openBox<String>('favorites');
  }

  Box<ChannelModel> get channelsBox => Hive.box<ChannelModel>('channels');
  Box<String> get favoritesBox => Hive.box<String>('favorites');
}
