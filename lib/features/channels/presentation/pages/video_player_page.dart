import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:omnistream_iptv/core/theme/cinematic_theme.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_glass_card.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_platform_badges.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';

// Imports para la Guía EPG y los nuevos controles de gestos
import 'package:omnistream_iptv/features/channels/presentation/widgets/epg_guide_view.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';

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
  bool _isLoading = false;
  Timer? _hideTimer;

  // --- ESTADO PARA GESTOS (VOLUMEN Y BRILLO) ---
  double _volume = 0.5;
  double _brightness = 0.5;
  bool _showVolumeIndicator = false;
  bool _showBrightnessIndicator = false;
  Timer? _indicatorTimer;
  // ----------------------------------------------------

  // ESTADO DE SELECCIÓN (MEMORIA MANUAL PARA AUDIO)
  String _savedAudioId = 'auto';
  String _savedSubtitleId = 'auto';

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

    // Inicializamos los valores de hardware
    _initHardwareControls();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 10 * 1024 * 1024, // 10MB: Equilibrio perfecto
        title: 'OmniStream Player',
      ),
    );

    // Optimizaciones de red
    (player.platform as dynamic).setProperty('network-timeout', '20');
    (player.platform as dynamic).setProperty('hls-bitrate', 'max');

    controller = VideoController(player);
    player.open(Media(_currentChannel.url));

    _startHideTimer();
    _startClock();
  }

  // --- CORRECCIÓN: Usar addListener en lugar de listener ---
  Future<void> _initHardwareControls() async {
    try {
      _volume = await VolumeController.instance.getVolume();
      _brightness = await ScreenBrightness().current;
      setState(() {});
    } catch (e) {
      debugPrint("Error inicializando controles: $e");
    }

    // CORREGIDO AQUÍ: El método se llama 'addListener' en la versión 3.4.0+
    VolumeController.instance.addListener((volume) {
      if (mounted) setState(() => _volume = volume);
    });
  }
  // ------------------------------------------------

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
      _isLoading = true;
      _savedAudioId = 'auto'; // Reset audio al cambiar canal
      _savedSubtitleId = 'auto';
    });

    (player.platform as dynamic).setProperty('aid', 'auto');
    (player.platform as dynamic).setProperty('sid', 'auto');

    player.open(Media(newChannel.url));

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  // --- LÓGICA DE GESTOS VERTICALES ---
  void _onVerticalDragUpdate(DragUpdateDetails details, bool isRightSide) {
    // Sensibilidad: deslizar hacia arriba (delta negativo) debe aumentar el valor
    final double delta = details.primaryDelta! / -200;

    setState(() {
      if (isRightSide) {
        // Derecha = Volumen
        _volume = (_volume + delta).clamp(0.0, 1.0);
        VolumeController.instance.setVolume(_volume);
        _showVolumeIndicator = true;
        _showBrightnessIndicator = false;
      } else {
        // Izquierda = Brillo
        _brightness = (_brightness + delta).clamp(0.0, 1.0);
        ScreenBrightness().setScreenBrightness(_brightness);
        _showBrightnessIndicator = true;
        _showVolumeIndicator = false;
      }
    });

    // Ocultar indicadores tras 1.5 segundos de inactividad
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
  // ------------------------------------------

  void _toggleChannelList() {
    setState(() {
      _isChannelListVisible = !_isChannelListVisible;
      if (_isChannelListVisible) {
        _areControlsVisible = false;
        _hideTimer?.cancel();
      } else {
        _areControlsVisible = true;
        _startHideTimer();
      }
    });
  }

  void _showEpgGuide() {
    setState(() => _areControlsVisible = false);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Cerrar Guía",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        final category = _currentChannel.group ?? "Otros";
        final channelsToShow =
            _channelsByCategory[category] ?? widget.channels ?? [];

        return Align(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: EpgGuideView(
              channels: channelsToShow,
              currentChannel: _currentChannel,
              onChannelSelected: (channel) {
                _switchChannel(channel);
              },
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: const Offset(0, 0))
              .animate(CurvedAnimation(parent: anim1, curve: Curves.easeInOut)),
          child: child,
        );
      },
    ).then((_) {
      _toggleControls();
    });
  }

  void _showSettingsDialog() {
    setState(() => _areControlsVisible = false);

    String audioLabel = "Auto";
    if (_savedAudioId == 'no')
      audioLabel = "Desactivado";
    else if (_savedAudioId != 'auto') {
      try {
        final track =
            player.state.tracks.audio.firstWhere((t) => t.id == _savedAudioId);
        audioLabel = track.language ?? track.title ?? "Pista $_savedAudioId";
      } catch (_) {
        audioLabel = "Pista $_savedAudioId";
      }
    }

    String subLabel = "Auto";
    if (_savedSubtitleId == 'no')
      subLabel = "Desactivado";
    else if (_savedSubtitleId != 'auto') {
      try {
        final track = player.state.tracks.subtitle
            .firstWhere((t) => t.id == _savedSubtitleId);
        subLabel = track.language ?? track.title ?? "Pista $_savedSubtitleId";
      } catch (_) {
        subLabel = "Pista $_savedSubtitleId";
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: CinematicGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text("Ajustes",
                      style: TextStyle(
                          color: CinematicColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: const Icon(Icons.audiotrack,
                      color: CinematicColors.accentSoft),
                  title: const Text("Audio",
                      style: TextStyle(color: CinematicColors.textPrimary)),
                  trailing: Text(audioLabel,
                      style: const TextStyle(color: CinematicColors.textMuted)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showTrackSelection("audio");
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.subtitles,
                      color: CinematicColors.accentSoft),
                  title: const Text("Subtítulos",
                      style: TextStyle(color: CinematicColors.textPrimary)),
                  trailing: Text(subLabel,
                      style: const TextStyle(color: CinematicColors.textMuted)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showTrackSelection("subtitle");
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      if (!_isChannelListVisible) _toggleControls();
    });
  }

  void _showTrackSelection(String type) {
    final isAudio = type == "audio";
    final tracks =
        isAudio ? player.state.tracks.audio : player.state.tracks.subtitle;
    final currentSavedId = isAudio ? _savedAudioId : _savedSubtitleId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: CinematicGlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
          child: Column(
            children: [
              Text("Seleccionar ${isAudio ? 'Audio' : 'Subtítulo'}",
                  style: const TextStyle(
                      color: CinematicColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    _buildTrackTile(ctx, type, "auto", "Auto (Por defecto)",
                        currentSavedId == 'auto'),
                    _buildTrackTile(
                        ctx, type, "no", "Desactivado", currentSavedId == 'no'),
                    const Divider(color: Colors.white24),
                    ...tracks.map((track) {
                      final label = track.language ??
                          track.title ??
                          track.id ??
                          "Desconocido";
                      return _buildTrackTile(ctx, type, track.id ?? "", label,
                          currentSavedId == track.id);
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackTile(
      BuildContext ctx, String type, String id, String label, bool isSelected) {
    return ListTile(
      selected: isSelected,
      selectedTileColor: CinematicColors.accent.withOpacity(0.2),
      leading: isSelected
          ? const Icon(Icons.check, color: CinematicColors.accentSoft)
          : const SizedBox(width: 24),
      title: Text(label,
          style: TextStyle(
              color: isSelected
                  ? CinematicColors.accentSoft
                  : CinematicColors.textPrimary)),
      onTap: () async {
        Navigator.pop(ctx);
        setState(() {
          _isLoading = true;
          if (type == "audio")
            _savedAudioId = id;
          else
            _savedSubtitleId = id;
        });

        if (type == "audio") {
          await (player.platform as dynamic).setProperty('aid', id);
        } else {
          await (player.platform as dynamic).setProperty('sid', id);
        }

        await player.open(Media(_currentChannel.url));

        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  void _startClock() {
    _updateTime();
    _clockTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
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
    _indicatorTimer?.cancel();

    // CORREGIDO: Usamos removeListener() en lugar de removeListener(listener)
    VolumeController.instance.removeListener();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 1. REPRODUCTOR
            Center(
              child: Video(
                  controller: controller,
                  controls: NoVideoControls,
                  fit: _videoFit),
            ),

            // 2. CAPA DE GESTOS
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _toggleControls,
                    onVerticalDragUpdate: (details) =>
                        _onVerticalDragUpdate(details, false),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _toggleControls,
                    onVerticalDragUpdate: (details) =>
                        _onVerticalDragUpdate(details, true),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),

            // 3. INDICADORES DE GESTOS
            if (_showVolumeIndicator)
              Center(
                child: CinematicGlassCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_volume == 0 ? Icons.volume_off : Icons.volume_up,
                          color: CinematicColors.textPrimary, size: 40),
                      const SizedBox(height: 10),
                      Text("${(_volume * 100).toInt()}%",
                          style: const TextStyle(
                              color: CinematicColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 100,
                        height: 5,
                        child: LinearProgressIndicator(
                            value: _volume,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                CinematicColors.accentSoft)),
                      ),
                    ],
                  ),
                ),
              ),

            if (_showBrightnessIndicator)
              Center(
                child: CinematicGlassCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.brightness_6,
                          color: CinematicColors.textPrimary, size: 40),
                      const SizedBox(height: 10),
                      Text("${(_brightness * 100).toInt()}%",
                          style: const TextStyle(
                              color: CinematicColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 100,
                        height: 5,
                        child: LinearProgressIndicator(
                            value: _brightness,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                CinematicColors.accent)),
                      ),
                    ],
                  ),
                ),
              ),

            // 4. LOADER
            if (_isLoading)
              Container(
                color: Colors.black,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                          color: CinematicColors.accentSoft),
                      SizedBox(height: 20),
                      Text("Cargando...",
                          style: TextStyle(
                              color: CinematicColors.textPrimary,
                              fontSize: 12))
                    ],
                  ),
                ),
              ),

            // 5. INTERFAZ DE CONTROLES
            if (_areControlsVisible && !_isChannelListVisible && !_isLoading)
              _buildMainInterface(),

            // 6. LISTA LATERAL
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: _isChannelListVisible ? 0 : -380,
              top: 0,
              bottom: 0,
              width: 380,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: CinematicGlassCard(
                  padding: EdgeInsets.zero,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                        width: double.infinity,
                        child: const Text("Guía de Canales",
                            style: TextStyle(
                                color: CinematicColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      ),
                      Expanded(
                        child: _channelsByCategory.isNotEmpty
                            ? ListView.builder(
                                itemCount: _sortedCategories.length,
                                itemBuilder: (context, index) {
                                  final category = _sortedCategories[index];
                                  final channels =
                                      _channelsByCategory[category]!;

                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                        dividerColor: Colors.transparent),
                                    child: ExpansionTile(
                                      title: Text(category,
                                          style: const TextStyle(
                                              color:
                                                  CinematicColors.textPrimary,
                                              fontWeight: FontWeight.bold)),
                                      iconColor: CinematicColors.accentSoft,
                                      collapsedIconColor:
                                          CinematicColors.textMuted,
                                      children: channels.map((ch) {
                                        final isSelected =
                                            ch.id == _currentChannel.id;
                                        return ListTile(
                                          contentPadding:
                                              const EdgeInsets.only(
                                                  left: 30, right: 10),
                                          selected: isSelected,
                                          selectedTileColor:
                                              CinematicColors.accent
                                                  .withOpacity(0.2),
                                          leading: SizedBox(
                                            width: 30,
                                            height: 30,
                                            child: ch.logoUrl != null &&
                                                    ch.logoUrl!.isNotEmpty
                                                ? Image.network(ch.logoUrl!,
                                                    errorBuilder: (c, e, s) =>
                                                        const Icon(Icons.tv,
                                                            color:
                                                                CinematicColors
                                                                    .textMuted,
                                                            size: 20))
                                                : const Icon(Icons.tv,
                                                    color: CinematicColors
                                                        .textMuted,
                                                    size: 20),
                                          ),
                                          title: Text(
                                            ch.name,
                                            style: TextStyle(
                                                color: isSelected
                                                    ? CinematicColors
                                                        .accentSoft
                                                    : CinematicColors.textMuted,
                                                fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          onTap: () => _switchChannel(ch),
                                        );
                                      }).toList(),
                                    ),
                                  );
                                },
                              )
                            : const Center(
                                child: CircularProgressIndicator(
                                    color: CinematicColors.accentSoft)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainInterface() {
    return Container(
      color: Colors.black.withOpacity(0.25),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: CinematicGlassCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: CinematicColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    if (_currentChannel.logoUrl != null &&
                        _currentChannel.logoUrl!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(right: 15),
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                            color:
                                CinematicColors.backgroundElevated.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: CinematicColors.stroke)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _currentChannel.logoUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.tv,
                                    color: CinematicColors.textMuted),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentChannel.name,
                            style: const TextStyle(
                                color: CinematicColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                      blurRadius: 10,
                                      color: Colors.black45)
                                ]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_currentChannel.group != null)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: CinematicColors.accent.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(_currentChannel.group!,
                                  style: const TextStyle(
                                      color: CinematicColors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ),
                          const SizedBox(height: 6),
                          CinematicPlatformBadges.placeholder(),
                        ],
                      ),
                    ),
                    const Icon(Icons.access_time,
                        color: CinematicColors.textMuted),
                    const SizedBox(width: 5),
                    Text(_currentTime,
                        style: const TextStyle(
                            color: CinematicColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                  blurRadius: 10, color: Colors.black54)
                            ])),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: CinematicGlassCard(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPlayerButton(Icons.list, "Canales", _toggleChannelList),
                    _buildPlayerButton(_getAspectRatioIcon(), _aspectRatioText,
                        _cycleAspectRatio),
                    FloatingActionButton(
                      backgroundColor: CinematicColors.accentSoft,
                      child: StreamBuilder<bool>(
                        stream: player.stream.playing,
                        initialData: true,
                        builder: (context, snapshot) {
                          return Icon(
                              (snapshot.data ?? true)
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: 30);
                        },
                      ),
                      onPressed: player.playOrPause,
                    ),
                    _buildPlayerButton(Icons.dvr, "Guía", _showEpgGuide),
                    _buildPlayerButton(
                        Icons.settings, "Ajustes", _showSettingsDialog),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAspectRatioIcon() {
    switch (_videoFit) {
      case BoxFit.cover:
        return Icons.zoom_out_map;
      case BoxFit.fill:
        return Icons.fit_screen;
      default:
        return Icons.aspect_ratio;
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
            Icon(icon,
                color: CinematicColors.textPrimary,
                size: 28,
                shadows: const [Shadow(blurRadius: 5, color: Colors.black)]),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: CinematicColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    shadows: [Shadow(blurRadius: 5, color: Colors.black)])),
          ],
        ),
      ),
    );
  }
}
