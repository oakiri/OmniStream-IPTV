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

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 32 * 1024 * 1024, 
        title: 'OmniStream Player',
      ),
    );
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
      // Opcional: Cerrar lista al elegir (_isChannelListVisible = false)
      // O dejarla abierta para zapping rápido. Aquí la dejamos abierta.
    });
    player.open(Media(newChannel.url));
    // No reiniciamos el timer aquí para que la lista siga visible
  }

  // LOGICA CORREGIDA: La lista detiene el temporizador
  void _toggleChannelList() {
    setState(() {
      _isChannelListVisible = !_isChannelListVisible;
      if (_isChannelListVisible) {
        _areControlsVisible = false;
        _hideTimer?.cancel(); // ¡IMPORTANTE! Paramos el reloj para que no se cierre
      } else {
        _areControlsVisible = true; // Si cerramos la lista, vuelven los controles
        _startHideTimer();
      }
    });
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

  // LOGICA CORREGIDA: El temporizador respeta la lista abierta
  void _startHideTimer() {
    _hideTimer?.cancel();
    if (_isChannelListVisible) return; // Si la lista está abierta, NO iniciamos cuenta atrás

    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _areControlsVisible = false;
          // No tocamos _isChannelListVisible aquí
        });
      }
    });
  }

  void _toggleControls() {
    // Si la lista está abierta, un toque la cierra
    if (_isChannelListVisible) {
      setState(() {
        _isChannelListVisible = false;
        _areControlsVisible = false; // También ocultamos controles al cerrar lista
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
                                    title: Text(
                                      category,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    iconColor: Colors.blueAccent,
                                    collapsedIconColor: Colors.white54,
                                    children: channels.map((ch) {
                                      final isSelected = ch.id == _currentChannel.id;
                                      return ListTile(
                                        contentPadding: const EdgeInsets.only(left: 30, right: 10),
                                        selected: isSelected,
                                        selectedTileColor: Colors.blueAccent.withOpacity(0.2),
                                        leading: const Icon(Icons.tv, size: 18, color: Colors.white54),
                                        title: Text(
                                          ch.name,
                                          style: TextStyle(
                                            color: isSelected ? Colors.blueAccent : Colors.white70,
                                            fontSize: 14,
                                          ),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentChannel.name,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        if (_currentChannel.group != null)
                          Text(_currentChannel.group!, style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.access_time, color: Colors.white70),
                  const SizedBox(width: 5),
                  Text(_currentTime, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
                  _buildPlayerButton(Icons.dvr, "Guía", () {}),
                  _buildPlayerButton(Icons.settings, "Ajustes", () {}),
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
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}