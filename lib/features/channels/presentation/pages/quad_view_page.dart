import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:omnistream_iptv/features/channels/domain/entities/channel.dart';

class QuadViewPage extends StatefulWidget {
  final List<Channel> channels;

  const QuadViewPage({Key? key, required this.channels}) : super(key: key);

  @override
  State<QuadViewPage> createState() => _QuadViewPageState();
}

class _QuadViewPageState extends State<QuadViewPage> {
  final List<Player> _players = [];
  final List<VideoController> _videoControllers = [];
  int _focusedPlayerIndex = 0;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 4; i++) {
      final player = Player();
      _players.add(player);
      _videoControllers.add(VideoController(player));
      if (i < widget.channels.length) {
        player.open(Media(widget.channels[i].url));
      }
    }
    _players[_focusedPlayerIndex].setVolume(100);
  }

  @override
  void dispose() {
    for (var player in _players) {
      player.dispose();
    }
    super.dispose();
  }

  void _setFocusedPlayer(int index) {
    setState(() {
      for (int i = 0; i < _players.length; i++) {
        _players[i].setVolume(i == index ? 100 : 0);
      }
      _focusedPlayerIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 16 / 9,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _setFocusedPlayer(index),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _focusedPlayerIndex == index
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Video(controller: _videoControllers[index]),
            ),
          );
        },
      ),
    );
  }
}
