import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:go_router/go_router.dart'; // Importante para context.pop()

import 'package:omnistream_iptv/injection_container.dart';
import 'package:omnistream_iptv/core/epg/epg_service.dart';
import 'package:omnistream_iptv/core/epg/epg_models.dart';
import 'package:omnistream_iptv/core/storage/recent_playback_store.dart';

import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_theme.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_top_bar.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_side_menu.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_glass_card.dart';

class VideoPlayerPage extends StatefulWidget {
  final Channel channel;
  final List<Channel>? channels;
  final String? playlistUrl;
  /// If true, controls auto-hide faster (e.g., after opening from previews / EPG).
  final bool quickOverlay;

  const VideoPlayerPage({
    super.key,
    required this.channel,
    this.channels,
    this.playlistUrl,
    this.quickOverlay = false,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final Player player;
  late final VideoController controller;
  final VolumeController _volumeController = VolumeController();

  // ESTADO UI
  bool _areControlsVisible = true;
  bool _isLoading = false; 
  Timer? _hideTimer;
  Timer? _clockTimer;
  String _currentTime = "";
  
  // ESTADO GESTOS
  double _volume = 0.5;
  double _brightness = 0.5;
  bool _showVolumeIndicator = false;
  bool _showBrightnessIndicator = false;
  Timer? _indicatorTimer;

  // ESTADO ASPECT RATIO (ZOOM)
  BoxFit _videoFit = BoxFit.contain;
  String _aspectRatioText = "Normal";

  // ESTADO SELECCIÓN (MEMORIA MANUAL)
  String _savedAudioId = 'auto';
  String _savedSubtitleId = 'auto';

  late Channel _currentChannel;

  // EPG (NOW/NEXT)
  EpgNowNext? _epgNowNext;
  bool _epgLoading = false;
  Timer? _epgTick;

  Future<void> _persistLastChannel(Channel ch) async {
    try {
      await sl<RecentPlaybackStore>().saveLastChannel(
        channel: ch,
        playlistUrl: widget.playlistUrl,
      );
    } catch (_) {
      // Silencioso: no debe romper reproducción.
    }
  }

  @override
  void initState() {
    super.initState();
    _currentChannel = widget.channel;
    _persistLastChannel(_currentChannel);
    
    // Forzar modo inmersivo y orientación horizontal para el video
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    player = Player(
        configuration: const PlayerConfiguration(
            bufferSize: 10 * 1024 * 1024, 
            title: 'VIVID Player'
        )
    );
    
    (player.platform as dynamic).setProperty('network-timeout', '20');
    (player.platform as dynamic).setProperty('hls-bitrate', 'max');
    (player.platform as dynamic).setProperty('reconnect', 'yes');

    controller = VideoController(player);
    player.open(Media(_currentChannel.url));

    _initHardwareControls();
    _startHideTimer();
    _startClock();

    _primeEpg();
    _epgTick = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      setState(() {
        // Refresh progress bar only
      });
    });
  }

  Future<void> _initHardwareControls() async {
    try {
      _volume = await _volumeController.getVolume();
      _brightness = await ScreenBrightness().current;
      setState(() {});
    } catch (_) {}

    _volumeController.listener((volume) {
      if (mounted) setState(() => _volume = volume);
    });
  }

  void _startClock() {
    _updateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _currentTime = intl.DateFormat('HH:mm').format(DateTime.now());
      });
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    final secs = widget.quickOverlay ? 2 : 5;
    _hideTimer = Timer(Duration(seconds: secs), () {
      if (mounted) setState(() => _areControlsVisible = false);
    });
  }

  void _showControlsFor(Duration d) {
    if (!mounted) return;
    setState(() => _areControlsVisible = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(d, () {
      if (mounted) setState(() => _areControlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() => _areControlsVisible = !_areControlsVisible);
    if (_areControlsVisible) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details, bool isRightSide) async {
    final double delta = details.primaryDelta! / -250; 

    if (isRightSide) {
      double newVol = (_volume + delta).clamp(0.0, 1.0);
      _volumeController.setVolume(newVol);
      setState(() {
        _volume = newVol;
        _showVolumeIndicator = true;
        _showBrightnessIndicator = false;
      });
    } else {
      double newBright = (_brightness + delta).clamp(0.0, 1.0);
      try {
        await ScreenBrightness().setScreenBrightness(newBright);
        setState(() {
          _brightness = newBright;
          _showBrightnessIndicator = true;
          _showVolumeIndicator = false;
        });
      } catch (_) {}
    }

    _indicatorTimer?.cancel();
    _epgTick?.cancel();
    _indicatorTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showVolumeIndicator = false;
          _showBrightnessIndicator = false;
        });
      }
    });
  }

  void _cycleAspectRatio() {
    setState(() {
      if (_videoFit == BoxFit.contain) {
        _videoFit = BoxFit.cover; 
        _aspectRatioText = "Zoom";
      } else if (_videoFit == BoxFit.cover) {
        _videoFit = BoxFit.fill; 
        _aspectRatioText = "Estirar";
      } else {
        _videoFit = BoxFit.contain; 
        _aspectRatioText = "Normal";
      }
    });
    
    _startHideTimer(); 
  }

  Future<void> _primeEpg({bool force = false}) async {
    setState(() => _epgLoading = true);
    try {
      await sl<EpgService>().ensureFresh(playlistUrl: widget.playlistUrl, force: force);
    } catch (_) {
      // Silencioso: si falla, simplemente no habrá EPG.
    }
    if (!mounted) return;
    setState(() {
      _epgNowNext = sl<EpgService>().lookupNowNext(_currentChannel);
      _epgLoading = false;
    });
  }

  Future<void> _openEpgTimeline() async {
    _hideTimer?.cancel();
    final channelsList = widget.channels ?? <Channel>[_currentChannel];
    final result = await context.pushNamed(
      'epg',
      extra: {
        'channels': channelsList,
        'currentChannel': _currentChannel,
        'playlistUrl': widget.playlistUrl,
        // If we open from the player, we want a selection that returns here.
        'returnSelection': true,
      },
    );

    if (!mounted) return;
    if (result is Channel) {
      setState(() {
        _currentChannel = result;
        _savedAudioId = 'auto';
        _savedSubtitleId = 'auto';
        player.open(Media(result.url));
        _epgNowNext = sl<EpgService>().lookupNowNext(result);
      });
      _persistLastChannel(result);
      // Premium feel: show overlays briefly after selection.
      _showControlsFor(const Duration(seconds: 2));
    } else {
      _startHideTimer();
    }
  }

  Future<void> _changeTrack(String type, String id) async {
    setState(() => _isLoading = true);
    
    if (type == "audio") _savedAudioId = id;
    else _savedSubtitleId = id;

    if (type == "audio") {
      await (player.platform as dynamic).setProperty('aid', id);
    } else {
      await (player.platform as dynamic).setProperty('sid', id);
    }

    await player.open(Media(_currentChannel.url));
    
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) setState(() => _isLoading = false);
  }

  void _showSettingsDialog() {
    _hideTimer?.cancel();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildSettingsPanel(),
    ).then((_) => _startHideTimer());
  }

  Widget _buildSettingsPanel() {
    final tracks = player.state.tracks;
    
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Ajustes de Reproducción", style: CinematicStyles.title.copyWith(fontSize: 20)),
            const SizedBox(height: 20),
            
            _buildTrackSection("Audio", tracks.audio, "audio", _savedAudioId),
            const Divider(color: Colors.white24, height: 30),
            _buildTrackSection("Subtítulos", tracks.subtitle, "subtitle", _savedSubtitleId),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackSection(String title, List<dynamic> tracks, String type, String currentId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: CinematicStyles.subtitle),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: [
            _buildChip("Auto", "auto", currentId == "auto", type),
            _buildChip("Desactivado", "no", currentId == "no", type),
            ...tracks.map((track) {
              String label = "Desconocido";
              String id = "";
              if (track is AudioTrack) {
                label = track.language ?? track.title ?? track.id;
                id = track.id;
              } else if (track is SubtitleTrack) {
                label = track.language ?? track.title ?? track.id;
                id = track.id;
              }
              if (id == 'auto') return const SizedBox.shrink();
              
              return _buildChip(label, id, currentId == id, type);
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(String label, String id, bool isSelected, String type) {
    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected ? CinematicColors.accent : Colors.white10,
      labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
      onPressed: () {
        Navigator.pop(context); 
        _changeTrack(type, id); 
      },
    );
  }

  @override
  void dispose() {
    player.dispose();
    _hideTimer?.cancel();
    _clockTimer?.cancel();
    _indicatorTimer?.cancel();
    _epgTick?.cancel();
    _volumeController.removeListener();
    
    // --- RESTAURAR ROTACIÓN (CRÍTICO) ---
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // CAPA 1: VIDEO (Con Zoom)
          Center(
            child: Video(
              controller: controller, 
              controls: NoVideoControls,
              fit: _videoFit, 
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: CinematicColors.accent),
              ),
            ),

          // CAPA 2: GESTOS
          Row(
            children: [
              Expanded(child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _toggleControls, onVerticalDragUpdate: (d) => _onVerticalDragUpdate(d, false), child: Container(color: Colors.transparent))),
              Expanded(child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _toggleControls, onVerticalDragUpdate: (d) => _onVerticalDragUpdate(d, true), child: Container(color: Colors.transparent))),
            ],
          ),

          // CAPA 3: UI CINEMATIC
          if (_areControlsVisible && !_isLoading) ...[
            const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black87, Colors.transparent, Colors.black87], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0.0, 0.5, 1.0])))),
            
            // BARRA SUPERIOR
            Positioned(
              top: 0, left: 0, right: 0, 
              child: CinematicTopBar(
                currentTime: _currentTime,
                aspectRatioText: _aspectRatioText, 
                onBack: () => context.pop(),
              )
            ),
            
            // MENÚ LATERAL
            Positioned(
              top: 0, bottom: 0, left: 0, 
              child: CinematicSideMenu(
                onEpgTap: _openEpgTimeline,
                onAspectRatioTap: _cycleAspectRatio,
                onSettingsTap: _showSettingsDialog,
              )
            ),
            // TARJETA DE INFO
            Positioned(
              bottom: 30, left: 100, right: 30,
              child: CinematicGlassCard(
                channel: _currentChannel, 
                isPlaying: player.state.playing, 
                onPlayPause: player.playOrPause,
                nowNext: _epgNowNext,
                epgLoading: _epgLoading,
                onEpgTap: _openEpgTimeline
              ),
            ),
          ],

          if ((_showVolumeIndicator || _showBrightnessIndicator) && !_isLoading)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_showVolumeIndicator ? Icons.volume_up : Icons.brightness_6, color: Colors.white, size: 48),
                    const SizedBox(height: 16),
                    Text("${((_showVolumeIndicator ? _volume : _brightness) * 100).toInt()}%", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    SizedBox(width: 150, height: 8, child: LinearProgressIndicator(value: _showVolumeIndicator ? _volume : _brightness, color: const Color(0xFF00A8E8), backgroundColor: Colors.white24, borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
