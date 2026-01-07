import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:omnistream_iptv/features/channels/domain/entities/channel.dart';

class VideoPlayerPage extends StatefulWidget {
  final Channel channel;

  const VideoPlayerPage({Key? key, required this.channel}) : super(key: key);

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final Player player;

  @override
  void initState() {
    super.initState();
    player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 32 * 1024 * 1024, // 32MB Buffer
        title: 'OmniStream Player',
      ),
    );
    player.open(Media(widget.channel.url));
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Video(
        controller: VideoController(player),
      ),
    );
  }
}
