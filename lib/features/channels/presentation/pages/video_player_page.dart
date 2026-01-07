
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:omnistream_iptv/features/channels/domain/entities/channel.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:intl/intl.dart';

class VideoPlayerPage extends StatefulWidget {
  final Channel channel;
  final List<Channel> channels;

  const VideoPlayerPage({Key? key, required this.channel, required this.channels})
      : super(key: key);

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> with WidgetsBindingObserver {
  late final Player player;
  late final VideoController videoController;
  Timer? _hideControlsTimer;
  bool _showControls = true;
  double _volume = 0.5;
  double _brightness = 0.5;
  int _batteryLevel = 100;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 32 * 1024 * 1024, // 32MB Buffer
        title: 'OmniStream Player',
      ),
    );
    videoController = VideoController(player);
    player.open(Media(widget.channel.url));
    _startHideControlsTimer();

    VolumeController.instance.getVolume().then((volume) {
      if (mounted) setState(() => _volume = volume);
    });

    ScreenBrightness().current.then((brightness) {
      if (mounted) setState(() => _brightness = brightness);
    });

    final battery = Battery();
    battery.onBatteryStateChanged.listen((state) {
      battery.batteryLevel.then((level) {
        if (mounted) setState(() => _batteryLevel = level);
      });
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateFormat.Hm().format(DateTime.now());
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideControlsTimer?.cancel();
    player.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      player.pause();
    } else if (state == AppLifecycleState.resumed) {
      player.play();
    }
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
      // Brightness
      setState(() {
        _brightness -= details.delta.dy / 200;
        _brightness = _brightness.clamp(0.0, 1.0);
        ScreenBrightness().setScreenBrightness(_brightness);
      });
    } else {
      // Volume
      setState(() {
        _volume -= details.delta.dy / 200;
        _volume = _volume.clamp(0.0, 1.0);
        VolumeController.instance.setVolume(_volume);
      });
    }
  }

  void _showChannelList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: 200,
          color: Colors.black.withOpacity(0.7),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.channels.length,
            itemBuilder: (context, index) {
              final channel = widget.channels[index];
              return GestureDetector(
                onTap: () {
                  player.open(Media(channel.url));
                  Navigator.of(context).pop();
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Image.network(channel.logoUrl ?? '', width: 80, height: 80, errorBuilder: (c, o, s) => const Icon(Icons.tv, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text(channel.name, style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        onDoubleTap: () => player.playOrPause(),
        onVerticalDragUpdate: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isLeft = details.globalPosition.dx < screenWidth / 2;
          _onVerticalDragUpdate(details, isLeft);
        },
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! < -1000) {
            _showChannelList();
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Video(controller: videoController),
            if (_showControls) _buildOsd(),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_currentTime, style: const TextStyle(color: Colors.white)),
          Row(
            children: [
              const Icon(Icons.battery_full, color: Colors.white),
              const SizedBox(width: 4),
              Text('$_batteryLevel%', style: const TextStyle(color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(widget.channel.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Row(
            children: [
              const Chip(label: Text('FHD')),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.aspect_ratio, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.circle, color: Colors.red, size: 16),
              const SizedBox(width: 4),
              const Text('LIVE', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _showChannelList,
                icon: const Icon(Icons.list, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
