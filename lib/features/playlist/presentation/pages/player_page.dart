import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';

class PlayerPage extends StatefulWidget {
  final Channel channel;

  const PlayerPage({
    Key? key,
    required this.channel,
  }) : super(key: key);

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late final Player player;
  late final VideoController videoController;
  bool _isPlaying = false;

  // --- LISTA DE IDENTIDADES (User-Agents) ---
  // El reproductor probar� estas identidades en orden hasta que una funcione.
  final List<String> _userAgents = [
    'IPTVSmartersPro',          // 1. El est�ndar m�s com�n en IPTV
    'VLC/3.0.0-git LibVLC/3.0.0-git', // 2. Simulamos ser VLC Player
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', // 3. Simulamos ser un navegador PC
    'ExoPlayer/2.18.1',         // 4. Simulamos ser un Android TV nativo
    'Dalvik/2.1.0 (Linux; U; Android 10; Mobile)', // 5. Android gen�rico
  ];

  @override
  void initState() {
    super.initState();
    // Inicializamos las variables
    player = Player();
    videoController = VideoController(player);

    // Iniciamos el proceso de carga autom�tico
    Future.microtask(() {
      _initializePlayer(); 
    });
  }

  // --- L�GICA DE REINTENTO AUTOM�TICO ---
  Future<void> _initializePlayer([int retryIndex = 0]) async {
    // CASO DE SALIDA: Si ya probamos toda la lista y nada funcion�
    if (retryIndex >= _userAgents.length) {
      print('[PlayerPage] Todos los User-Agents fallaron.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo reproducir el canal. Servidor rechaza la conexi�n.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // Seleccionamos el User-Agent actual
    final currentUserAgent = _userAgents[retryIndex];

    try {
      print('[PlayerPage] Intento #${retryIndex + 1} conectando como: "$currentUserAgent"');
      print('[PlayerPage] URL: ${widget.channel.url}');

      // Configuramos los headers para "enga�ar" al servidor
      final headers = {
        'User-Agent': currentUserAgent,
      };

      // Intentamos abrir el video
      await player.open(
        Media(
          widget.channel.url,
          httpHeaders: headers, // <--- Aqu� enviamos la identidad
        ),
        play: true,
      );

      // Si llegamos aqu� sin excepci�n, asumimos que conect�.
      // (Nota: MediaKit a veces no lanza excepci�n inmediata en streams, 
      // pero si el video arranca, es un �xito).
      print('[PlayerPage] �Conexi�n aceptada con $currentUserAgent!');
      
      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
      }

    } catch (e) {
      print('[PlayerPage] Fall� con $currentUserAgent. Error: $e');
      print('[PlayerPage] Reintentando con la siguiente identidad...');
      
      // RECURSIVIDAD: Llamamos a la misma funci�n pero con el siguiente �ndice
      await _initializePlayer(retryIndex + 1);
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      player.pause();
    } else {
      player.play();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  @override
  void dispose() {
    print('[PlayerPage] Cerrando reproductor...');
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.channel.name,
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              child: Video(controller: videoController),
            ),
          ),
          _buildPlayerControls(),
          _buildChannelInfo(),
        ],
      ),
    );
  }

  Widget _buildPlayerControls() {
    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: _togglePlayPause,
          ),
          IconButton(
            icon: const Icon(Icons.volume_up, color: Colors.white),
            onPressed: () {
              // Aqu� podr�as implementar control de volumen
            },
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen, color: Colors.white),
            onPressed: () {
              // Aqu� podr�as implementar pantalla completa
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChannelInfo() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16),
      width: double.infinity, // Asegura que ocupe todo el ancho
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informaci�n del Canal',
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nombre: ${widget.channel.name}',
            style: GoogleFonts.roboto(fontSize: 12),
          ),
          if (widget.channel.group != null)
            Text(
              'Categor�a: ${widget.channel.group}',
              style: GoogleFonts.roboto(fontSize: 12),
            ),
          const SizedBox(height: 4),
          // Mostramos la URL cortada para depuraci�n visual
          Text(
            'Stream: ${widget.channel.url}',
            style: GoogleFonts.roboto(fontSize: 10, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}