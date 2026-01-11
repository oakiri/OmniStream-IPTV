import 'dart:async';
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
  
  // ESTADO INTERFAZ
  bool _areControlsVisible = true;
  bool _isChannelListVisible = false;
  Timer? _hideTimer;

  // ESTADO DATOS
  late Channel _currentChannel;
  Map<String, List<Channel>> _channelsByCategory = {}; 
  List<String> _sortedCategories = [];

  // ESTADO RELOJ & PANTALLA
  String _currentTime = "00:00";
  Timer? _clockTimer;
  BoxFit _videoFit = BoxFit.contain; 
  String _aspectRatioText = "Normal"; 

  @override
  void initState() {
    super.initState();
    _currentChannel = widget.channel;
    _groupChannels();

    // 1. MODO CINE
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // 2. CONFIGURACIÓN MOTOR
    player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 32 * 1024 * 1024, 
        title: 'OmniStream Player',
      ),
    );
    // Ajustes finos para IPTV
    (player.platform as dynamic).setProperty('demuxer-max-bytes', (128 * 1024 * 1024).toString());
    (player.platform as dynamic).setProperty('demuxer-max-back-bytes', (32 * 1024 * 1024).toString());
    (player.platform as dynamic).setProperty('network-timeout', '20');

    controller = VideoController(player);
    player.open(Media(_currentChannel.url));
    
    _startHideTimer();
    _startClock();
  }

  void _groupChannels() {
    if (widget.channels == null) return;
    for (var channel in widget.channels!) {
      final categoryName = channel.group ?? "Otros"; 
      if (!_channelsByCategory.containsKey(categoryName)) {
        _channelsByCategory[categoryName] = [];
      }
      _channelsByCategory[categoryName]!.add(channel);
    }
    _sortedCategories = _channelsByCategory.keys.toList()..sort();
  }

  void _switchChannel(Channel newChannel) {
    setState(() {
      _currentChannel = newChannel;
    });
    player.open(Media(newChannel.url));
    // No reseteamos timer para permitir zapping rápido continuo
  }

  void _toggleChannelList() {
    setState(() {
      _isChannelListVisible = !_isChannelListVisible;
      if (_isChannelListVisible) {
        _areControlsVisible = false;
        _hideTimer?.cancel(); // Parar timer para que la lista no se cierre sola
      } else {
        _areControlsVisible = true;
        _startHideTimer();
      }
    });
  }

  // --- LOGICA DE AUDIO Y SUBTÍTULOS ---
  void _showSettingsDialog() {
    // Ocultamos controles primero para limpiar la pantalla
    setState(() => _areControlsVisible = false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text("Ajustes de Reproducción", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.audiotrack, color: Colors.blueAccent),
                title: const Text("Pista de Audio", style: TextStyle(color: Colors.white)),
                trailing: Text(player.state.track.audio.id == 'no' ? 'Desactivado' : (player.state.track.audio.language ?? player.state.track.audio.id ?? "Auto"), style: const TextStyle(color: Colors.white54)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showTrackSelection("audio");
                },
              ),
              ListTile(
                leading: const Icon(Icons.subtitles, color: Colors.blueAccent),
                title: const Text("Subtítulos", style: TextStyle(color: Colors.white)),
                trailing: Text(player.state.track.subtitle.id == 'no' ? 'Desactivado' : (player.state.track.subtitle.language ?? player.state.track.subtitle.id ?? "Auto"), style: const TextStyle(color: Colors.white54)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showTrackSelection("subtitle");
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ).then((_) {
      // Al cerrar el diálogo, si no hay lista visible, mostrar controles brevemente
      if (!_isChannelListVisible) _toggleControls();
    });
  }

  void _showTrackSelection(String type) {
    final tracks = type == "audio" ? player.state.tracks.audio : player.state.tracks.subtitle;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text("Seleccionar ${type == 'audio' ? 'Audio' : 'Subtítulo'}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  // Determinamos si es el activo
                  final isActive = type == "audio" 
                      ? player.state.track.audio == track 
                      : player.state.track.subtitle == track;

                  return ListTile(
                    selected: isActive,
                    selectedTileColor: Colors.blueAccent.withOpacity(0.2),
                    leading: isActive ? const Icon(Icons.check, color: Colors.blueAccent) : const SizedBox(width: 24),
                    title: Text(
                      track.language ?? track.title ?? track.id ?? "Desconocido",
                      style: TextStyle(color: isActive ? Colors.blueAccent : Colors.white),
                    ),
                    onTap: () {
                      if (type == "audio") {
                        player.setAudioTrack(track as AudioTrack);
                      } else {
                        player.setSubtitleTrack(track as SubtitleTrack);
                      }
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startClock() {
    _updateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    if (mounted) setState(() => _currentTime = "$hour:$minute");
  }

  void _cycleAspectRatio() {
    setState(() {
      if (_videoFit == BoxFit.contain) {
        _videoFit = BoxFit.cover; _aspectRatioText = "Zoom";
      } else if (_videoFit == BoxFit.cover) {
        _videoFit = BoxFit.fill; _aspectRatioText = "Estirar";
      } else {
        _videoFit = BoxFit.contain; _aspectRatioText = "Normal";
      }
    });
    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    if (_isChannelListVisible) return;

    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _areControlsVisible = false);
      }
    });
  }

  void _toggleControls() {
    if (_isChannelListVisible) {
      setState(() {
        _isChannelListVisible = false;
        _areControlsVisible = false;
      });
      return;
    }
    setState(() => _areControlsVisible = !_areControlsVisible);
    if (_areControlsVisible) _startHideTimer();
  }

  @override
  void dispose() {
    player.dispose();
    _hideTimer?.cancel();
    _clockTimer?.cancel();
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
          onTap: _toggleControls,
          child: Stack(
            children: [
              Center(
                child: Video(controller: controller, controls: NoVideoControls, fit: _videoFit),
              ),

              if (_areControlsVisible && !_isChannelListVisible)
                _buildMainInterface(),

              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: _isChannelListVisible ? 0 : -380,
                top: 0, bottom: 0,
                width: 380,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.95),
                    boxShadow: [BoxShadow(color: Colors.black, blurRadius: 20, spreadRadius: 5)],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                        color: Colors.white10,
                        width: double.infinity,
                        child: const Text("Guía de Canales", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                      Expanded(
                        child: _channelsByCategory.isNotEmpty 
                          ? ListView.builder(
                              itemCount: _sortedCategories.length,
                              itemBuilder: (context, index) {
                                final category = _sortedCategories[index];
                                final channels = _channelsByCategory[category]!;
                                
                                return Theme(
                                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                  child: ExpansionTile(
                                    title: Text(category, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    iconColor: Colors.blueAccent,
                                    collapsedIconColor: Colors.white54,
                                    children: channels.map((ch) {
                                      final isSelected = ch.id == _currentChannel.id;
                                      return ListTile(
                                        contentPadding: const EdgeInsets.only(left: 30, right: 10),
                                        selected: isSelected,
                                        selectedTileColor: Colors.blueAccent.withOpacity(0.2),
                                        leading: SizedBox(
                                          width: 30, height: 30,
                                          child: ch.logoUrl != null && ch.logoUrl!.isNotEmpty 
                                            ? Image.network(ch.logoUrl!, errorBuilder: (c,e,s) => const Icon(Icons.tv, color: Colors.white54, size: 20))
                                            : const Icon(Icons.tv, color: Colors.white54, size: 20),
                                        ),
                                        title: Text(
                                          ch.name,
                                          style: TextStyle(color: isSelected ? Colors.blueAccent : Colors.white70, fontSize: 14),
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                        ),
                                        onTap: () => _switchChannel(ch),
                                      );
                                    }).toList(),
                                  ),
                                );
                              },
                            )
                          : const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
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

  Widget _buildMainInterface() {
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  
                  // --- LOGO DEL CANAL ---
                  if (_currentChannel.logoUrl != null && _currentChannel.logoUrl!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(right: 15),
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _currentChannel.logoUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.tv, color: Colors.white54),
                        ),
                      ),
                    ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentChannel.name,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 10, color: Colors.black)]),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        if (_currentChannel.group != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.8), borderRadius: BorderRadius.circular(4)),
                            child: Text(_currentChannel.group!, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.access_time, color: Colors.white70),
                  const SizedBox(width: 5),
                  Text(_currentTime, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 10, color: Colors.black)])),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPlayerButton(Icons.list, "Canales", _toggleChannelList),
                  _buildPlayerButton(_getAspectRatioIcon(), _aspectRatioText, _cycleAspectRatio),
                  FloatingActionButton(
                    backgroundColor: Colors.blueAccent,
                    child: StreamBuilder<bool>(
                      stream: player.stream.playing,
                      builder: (context, snapshot) {
                        return Icon((snapshot.data ?? false) ? Icons.pause : Icons.play_arrow, size: 30);
                      },
                    ),
                    onPressed: player.playOrPause,
                  ),
                  _buildPlayerButton(Icons.dvr, "Guía", () {}), // Próximamente EPG
                  _buildPlayerButton(Icons.settings, "Ajustes", _showSettingsDialog), // <-- AHORA FUNCIONA
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAspectRatioIcon() {
    switch (_videoFit) {
      case BoxFit.cover: return Icons.zoom_out_map;
      case BoxFit.fill: return Icons.fit_screen;
      default: return Icons.aspect_ratio;
    }
  }

  Widget _buildPlayerButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 28, shadows: const [Shadow(blurRadius: 5, color: Colors.black)]),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500, shadows: [Shadow(blurRadius: 5, color: Colors.black)])),
          ],
        ),
      ),
    );
  }
}