import 'package:hive/hive.dart';
import 'package:omnistream_iptv/features/playlist/data/models/channel_model.dart';

abstract class PlaylistLocalDataSource {
  Future<void> cacheChannels(List<ChannelModel> channels);
  Future<List<ChannelModel>> getLastChannels();
}

class PlaylistLocalDataSourceImpl implements PlaylistLocalDataSource {
  final Box<ChannelModel> channelBox;

  PlaylistLocalDataSourceImpl({required this.channelBox});

  @override
  Future<void> cacheChannels(List<ChannelModel> channels) {
    return channelBox.addAll(channels);
  }

  @override
  Future<List<ChannelModel>> getLastChannels() {
    return Future.value(channelBox.values.toList());
  }
}
