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
  late final VideoController controller;

  @override
  void initState() {
    super.initState();
    
    // 1. Configuración básica
    player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 32 * 1024 * 1024,
        title: 'OmniStream Player',
      ),
    );

    // 2. Controladores (Añadimos logs para ver qué pasa)
    controller = VideoController(player);

    // --- ZONA DE DIAGNÓSTICO ---
    player.stream.error.listen((event) {
      print('🚨 ERROR DEL PLAYER: $event');
    });
    
    player.stream.log.listen((event) {
      print('ℹ️ LOG PLAYER: $event');
    });

    player.stream.buffering.listen((event) {
      print('⏳ BUFFERING: $event');
    });
    // ---------------------------

    // 3. Cargar canal
    print('🚀 Intentando abrir: ${widget.channel.url}');
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.channel.name), // Ver el nombre ayuda a saber que cargó la página
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Video(
            controller: controller,
            // Quitamos 'NoVideoControls' para que veas si sale la interfaz al menos
            // controls: NoVideoControls, 
          ),
        ),
      ),
    );
  }
}
