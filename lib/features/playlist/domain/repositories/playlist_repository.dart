import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';

abstract class PlaylistRepository {
  Future<List<Channel>> getChannels(String url);
}
