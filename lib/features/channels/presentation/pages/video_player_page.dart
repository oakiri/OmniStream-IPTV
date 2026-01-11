import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';

class VideoPlayerPage extends StatefulWidget {
  final Channel channel;
  final List<Channel>? channels; 

  const VideoPlayerPage({
    Key? key, 
    required this.channel,
    this.channels,
  }) : super(key: key);

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final Player player;
  late final VideoController controller;

  @override
  void initState() {
    super.initState();
    
    // 1. Configuración optimizada para IPTV y streams pesados
    player = Player(
      configuration: const PlayerConfiguration(
        // Aumentamos el buffer a 32MB (en bytes) para evitar cortes en 4K/UHD
        bufferSize: 32 * 1024 * 1024, 
        title: 'OmniStream Player',
      ),
    );

    // 2. Ajustes finos del motor (libmpv) para estabilidad en redes móviles/WiFi
    // 'demuxer-max-bytes': Permite cargar hasta 128MB en RAM por adelantado si es necesario
    (player.platform as dynamic).setProperty('demuxer-max-bytes', (128 * 1024 * 1024).toString());
    // 'demuxer-max-back-bytes': Buffer hacia atrás (para rebobinar un poco si se congela)
    (player.platform as dynamic).setProperty('demuxer-max-back-bytes', (32 * 1024 * 1024).toString());
    // 'network-timeout': Esperar hasta 20 segundos antes de dar error de conexión
    (player.platform as dynamic).setProperty('network-timeout', '20');

    // 3. Inicializar controlador y abrir stream
    controller = VideoController(player);
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
      body: Center(
        child: Video(controller: controller),
      ),
    );
  }
}