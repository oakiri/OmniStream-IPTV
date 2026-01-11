import 'dart:async'; // Necesario para el temporizador de ocultar controles
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  
  // ESTADO DE LA INTERFAZ
  bool _areControlsVisible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    
    // 1. MODO CINE (Recuperado)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // 2. CONFIGURACIÓN MOTOR (Tu configuración optimizada)
    player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 32 * 1024 * 1024, 
        title: 'OmniStream Player',
      ),
    );
    (player.platform as dynamic).setProperty('demuxer-max-bytes', (128 * 1024 * 1024).toString());
    (player.platform as dynamic).setProperty('demuxer-max-back-bytes', (32 * 1024 * 1024).toString());
    (player.platform as dynamic).setProperty('network-timeout', '20');

    // 3. INICIO
    controller = VideoController(player);
    player.open(Media(widget.channel.url));
    
    // Iniciar temporizador para ocultar controles
    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _areControlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() {
      _areControlsVisible = !_areControlsVisible;
    });
    if (_areControlsVisible) _startHideTimer();
  }

  @override
  void dispose() {
    player.dispose();
    _hideTimer?.cancel();
    // Restaurar móvil a vertical
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _toggleControls, // Tocar pantalla muestra/oculta interfaz
          child: Stack(
            children: [
              // CAPA 1: EL VÍDEO (Fondo)
              Center(
                child: Video(
                  controller: controller,
                  controls: NoVideoControls, // ¡IMPORTANTE! Desactivamos los controles por defecto
                ),
              ),

              // CAPA 2: TU DISEÑO PERSONALIZADO (Overlay)
              if (_areControlsVisible)
                Container(
                  color: Colors.black.withOpacity(0.4), // Velo oscuro para que se lean las letras
                  child: SafeArea(
                    child: Column(
                      children: [
                        // --- ZONA SUPERIOR (Header) ---
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              // Botón Atrás
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const SizedBox(width: 10),
                              // Nombre del Canal y Logo
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.channel.name, // Nombre dinámico del canal
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    if (widget.channel.tvgId != null)
                                      Text(
                                        "En vivo", // Aquí iría la info EPG futura
                                        style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
                                      ),
                                  ],
                                ),
                              ),
                              // Reloj (Simulado por ahora)
                              const Icon(Icons.access_time, color: Colors.white70),
                              const SizedBox(width: 5),
                              const Text("12:00 PM", style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),

                        const Spacer(), // Empuja todo lo demás hacia abajo

                        // --- ZONA INFERIOR (Controles) ---
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildPlayerButton(Icons.list, "Canales", () {}),
                              _buildPlayerButton(Icons.aspect_ratio, "Pantalla", () {}),
                              
                              // Botón Play/Pause Gigante Central
                              FloatingActionButton(
                                backgroundColor: Colors.blueAccent,
                                child: StreamBuilder<bool>(
                                  stream: player.stream.playing,
                                  builder: (context, snapshot) {
                                    final playing = snapshot.data ?? false;
                                    return Icon(playing ? Icons.pause : Icons.play_arrow, size: 30);
                                  },
                                ),
                                onPressed: player.playOrPause,
                              ),

                              _buildPlayerButton(Icons.dvr, "Guía", () {}),
                              _buildPlayerButton(Icons.settings, "Ajustes", () {}),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
}