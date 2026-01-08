import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:omnistream_iptv/features/channels/domain/entities/channel.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:screen_brightness/screen_brightness.dart';

class VideoPlayerPage extends StatefulWidget {
  final Channel channel;
  final List<Channel> channels;

  const VideoPlayerPage({Key? key, required this.channel, required this.channels})
      : super(key: key);

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final Player player;
  late final VideoController videoController;
  Timer? _hideControlsTimer;
  bool _showControls = true;
  double _volume = 0.5;
  double _brightness = 0.5;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 64 * 1024 * 1024, // 64MB para streams estables
      ),
    );
    videoController = VideoController(player);
    // Abrir el stream con opciones de bajo delay
    player.open(
      Media(
        widget.channel.url,
        httpHeaders: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ),
      play: true, // Comenzar a reproducir inmediatamente
    );
    _startHideControlsTimer();

    VolumeController.instance.getVolume().then((volume) {
      if (mounted) setState(() => _volume = volume);
    });

    ScreenBrightness().current.then((brightness) {
      if (mounted) setState(() => _brightness = brightness);
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _hideControlsTimer?.cancel();
    player.dispose();
    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _startHideControlsTimer();
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details, bool isLeft) {
    if (isLeft) {
      setState(() {
        _brightness -= details.delta.dy / 200;
        _brightness = _brightness.clamp(0.0, 1.0);
        ScreenBrightness().setScreenBrightness(_brightness);
      });
    } else {
      setState(() {
        _volume -= details.delta.dy / 200;
        _volume = _volume.clamp(0.0, 1.0);
        VolumeController.instance.setVolume(_volume);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        onVerticalDragUpdate: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isLeft = details.globalPosition.dx < screenWidth / 2;
          _onVerticalDragUpdate(details, isLeft);
        },
        child: Stack(
          children: [
            Video(controller: videoController),
            _buildVolumeBar(),
            _buildBrightnessBar(),
            if (_showControls) _buildOsd(),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeBar() {
    return Positioned(
      right: 20,
      top: 100,
      bottom: 100,
      child: RotatedBox(
        quarterTurns: 3,
        child: SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            value: _volume,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildBrightnessBar() {
    return Positioned(
      left: 20,
      top: 100,
      bottom: 100,
      child: RotatedBox(
        quarterTurns: 3,
        child: SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            value: _brightness,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildOsd() {
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTopBar(),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.channel.name,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Row(
            children: [
              Icon(Icons.network_check, color: Colors.white),
              SizedBox(width: 8),
              Text('FHD', style: TextStyle(color: Colors.white)),
              SizedBox(width: 16),
              Icon(Icons.circle, color: Colors.red, size: 16),
              SizedBox(width: 4),
              Text('LIVE', style: TextStyle(color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.grid_view, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
