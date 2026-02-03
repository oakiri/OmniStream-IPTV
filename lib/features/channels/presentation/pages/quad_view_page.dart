import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';

class QuadViewPage extends StatefulWidget {
  final List<Channel> channels;

  const QuadViewPage({Key? key, required this.channels}) : super(key: key);

  @override
  State<QuadViewPage> createState() => _QuadViewPageState();
}

class _QuadViewPageState extends State<QuadViewPage> {
  late final List<Player> players;
  late final List<VideoController> controllers;

  @override
  void initState() {
    super.initState();
    final count = widget.channels.length > 4 ? 4 : widget.channels.length;
    players = List.generate(count, (_) => Player());
    controllers = players.map((p) => VideoController(p)).toList();

    for (var i = 0; i < count; i++) {
      // Usamos .url correctamente
      players[i].open(Media(widget.channels[i].url)); 
    }
  }

  @override
  void dispose() {
    for (var p in players) p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Multiview')),
      body: GridView.builder(
        itemCount: controllers.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 16 / 9,
        ),
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(border: Border.all(color: Colors.white24)),
            child: Video(controller: controllers[index]),
          );
        },
      ),
    );
  }
}