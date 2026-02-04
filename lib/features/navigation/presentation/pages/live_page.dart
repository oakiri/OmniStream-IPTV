import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:omnistream_iptv/features/navigation/presentation/pages/live_epg_hub_page.dart';

class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  late final PlaylistBloc _playlistBloc;
  final RecentPlaybackStore _recentPlaybackStore = sl<RecentPlaybackStore>();
  final GetPlaylistProfiles _getPlaylistProfiles = sl<GetPlaylistProfiles>();

  bool _bootstrapping = true;
  String? _playlistUrl;
  String? _bootstrapError;

  @override
  void initState() {
    super.initState();
    _playlistBloc = sl<PlaylistBloc>();
    _bootstrap();
  }

  @override
  void dispose() {
    _playlistBloc.close();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _bootstrapping = true;
      _bootstrapError = null;
    });

    try {
      final playlistUrl = await _resolvePlaylistUrl();
      if (!mounted) return;

      if (playlistUrl == null || playlistUrl.isEmpty) {
        setState(() {
          _bootstrapping = false;
          _playlistUrl = null;
        });
        return;
      }

      setState(() {
        _bootstrapping = false;
        _playlistUrl = playlistUrl;
      });

      _playlistBloc.add(LoadPlaylist(playlistUrl));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bootstrapping = false;
        _bootstrapError = e.toString();
      });
    }
  }

  Future<String?> _resolvePlaylistUrl() async {
    final last = await _recentPlaybackStore.loadLastChannel();
    final lastUrl = (last?.playlistUrl ?? '').trim();
    if (lastUrl.isNotEmpty) return lastUrl;

    final profilesResult = await _getPlaylistProfiles(NoParams());
    final profiles = profilesResult.fold((_) => const <PlaylistProfile>[], (v) => v);
    return _pickLatestPlaylistUrl(profiles);
  }

  String? _pickLatestPlaylistUrl(List<PlaylistProfile> profiles) {
    final candidates = profiles.where((p) => p.url.trim().isNotEmpty).toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      final aDate = a.lastUsed ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.lastUsed ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return candidates.first.url.trim();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _playlistBloc,
      child: BlocBuilder<PlaylistBloc, PlaylistState>(
        builder: (context, state) {
          if (_bootstrapping) {
            return const _LiveLoadingState();
          }

          if (_bootstrapError != null) {
            return _LiveErrorState(message: _bootstrapError ?? '', onRetry: _bootstrap);
          }

          final playlistUrl = _playlistUrl;
          if (playlistUrl == null || playlistUrl.isEmpty) {
            return _LiveEmptyState(onSelectPlaylist: () => context.go('/playlist'));
          }

          if (state is PlaylistLoaded && state.channels.isNotEmpty) {
            return EpgTimelinePage(
              channels: state.channels,
              playlistUrl: playlistUrl,
            );
          }

          if (state is PlaylistError) {
            return _LiveErrorState(
              message: state.message,
              onRetry: () => _playlistBloc.add(LoadPlaylist(playlistUrl)),
            );
          }

          return const _LiveLoadingState();
        },
      ),
    );
  }
}

class _LiveLoadingState extends StatelessWidget {
  const _LiveLoadingState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.35,
                  colors: [Color(0xFF181818), Colors.black],
                ),
              ),
            ),
          ),
          const SafeArea(
            child: Center(
              child: CircularProgressIndicator(color: CinematicColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LiveErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.35,
                  colors: [Color(0xFF181818), Colors.black],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.white70, size: 36),
                    const SizedBox(height: 12),
                    Text(
                      'No se pudo cargar el EPG en vivo',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(color: Colors.white54, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text('Reintentar', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CinematicColors.accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveEmptyState extends StatelessWidget {
  final VoidCallback onSelectPlaylist;

  const _LiveEmptyState({required this.onSelectPlaylist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.35,
                  colors: [Color(0xFF181818), Colors.black],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.white.withOpacity(0.06),
                        border: Border.all(color: CinematicColors.accent.withOpacity(0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: CinematicColors.accent.withOpacity(0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.live_tv_rounded, color: Colors.white70, size: 44),
                          const SizedBox(height: 14),
                          Text(
                            'Activa tu EPG en vivo',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Selecciona una playlist para visualizar la guía en vivo con timeline y programación.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(color: Colors.white54, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            onPressed: onSelectPlaylist,
                            icon: const Icon(Icons.playlist_play_rounded, size: 18),
                            label: Text('Seleccionar lista', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CinematicColors.accent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return const LiveEpgHubPage();
  }
}
