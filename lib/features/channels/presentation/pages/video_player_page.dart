import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:go_router/go_router.dart'; // Importante para context.pop()

import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';
import 'package:omnistream_iptv/features/channels/presentation/widgets/epg_guide_view.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_theme.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_top_bar.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_side_menu.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_glass_card.dart';

class VideoPlayerPage extends StatefulWidget {
  final Channel channel;
  final List<Channel>? channels;

  const VideoPlayerPage({
    super.key,
    required this.channel,
    this.channels,
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

  @override
  void initState() {
    super.initState();
    _currentChannel = widget.channel;
    
    // Forzar modo inmersivo y orientación horizontal para el video
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    player = Player(
        configuration: const PlayerConfiguration(
            bufferSize: 10 * 1024 * 1024, 
            title: 'OmniStream Player'
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
        _currentTime = DateFormat('HH:mm').format(DateTime.now());
      });
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
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

  void _showEpgGuide() {
    _hideTimer?.cancel(); 
    final channelsList = widget.channels ?? [_currentChannel]; 

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Guía",
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => EpgGuideView(
        channels: channelsList,
        currentChannel: _currentChannel,
        onChannelSelected: (newChannel) {
          setState(() {
            _currentChannel = newChannel;
            _savedAudioId = 'auto'; 
            _savedSubtitleId = 'auto';
            player.open(Media(newChannel.url));
          });
        },
      ),
    ).then((_) => _startHideTimer());
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
    _volumeController.removeListener();
    
    // --- CORRECCIÓN IMPORTANTE: RESTAURAR ROTACIÓN ---
    // Restaurar todas las orientaciones permitidas al salir
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Restaurar UI del sistema
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
              )
            ),
            
            // MENÚ LATERAL
            Positioned(
              top: 0, bottom: 0, left: 0, 
              child: CinematicSideMenu(
                onEpgTap: _showEpgGuide,
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
                onPlayPause: player.playOrPause
              ),
            ),

            // --- AÑADIDO: BOTÓN VOLVER (BACK BUTTON) ---
            Positioned(
              top: 30, // Ajustado para que no choque con la barra de estado
              left: 20,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.pop(), // Acción de volver
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  ),
                ),
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