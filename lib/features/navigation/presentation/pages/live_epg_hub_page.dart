import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import 'package:omnistream_iptv/core/epg/epg_service.dart';
import 'package:omnistream_iptv/core/storage/recent_playback_store.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_theme.dart';
import 'package:omnistream_iptv/features/navigation/presentation/pages/epg_timeline_page.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/playlist_profile.dart';
import 'package:omnistream_iptv/features/playlist/domain/usecases/get_playlist.dart';
import 'package:omnistream_iptv/features/playlist/domain/usecases/get_playlist_profiles.dart';
import 'package:omnistream_iptv/core/usecases/no_params.dart';
import 'package:omnistream_iptv/injection_container.dart';

class LiveEpgHubPage extends StatefulWidget {
  const LiveEpgHubPage({super.key});

  @override
  State<LiveEpgHubPage> createState() => _LiveEpgHubPageState();
}

class _LiveEpgHubPageState extends State<LiveEpgHubPage> {
  final GetPlaylist _getPlaylist = sl<GetPlaylist>();
  final GetPlaylistProfiles _getPlaylistProfiles = sl<GetPlaylistProfiles>();
  final RecentPlaybackStore _recentPlaybackStore = sl<RecentPlaybackStore>();
  final EpgService _epgService = sl<EpgService>();

  bool _loading = true;
  String? _error;
  String? _playlistUrl;
  List<Channel> _channels = const <Channel>[];
  Channel? _currentChannel;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final last = await _recentPlaybackStore.loadLastChannel();
      Channel? current = last?.toChannel();
      String? playlistUrl = (last?.playlistUrl ?? '').trim();

      if (playlistUrl.isEmpty) {
        final profilesResult = await _getPlaylistProfiles(NoParams());
        playlistUrl = _pickLatestPlaylistUrl(profilesResult.fold((_) => const <PlaylistProfile>[], (v) => v));
      }

      if (playlistUrl == null || playlistUrl.isEmpty) {
        setState(() {
          _loading = false;
          _playlistUrl = null;
          _channels = const <Channel>[];
          _currentChannel = current;
        });
        return;
      }

      final playlistResult = await _getPlaylist(playlistUrl);
      final channels = playlistResult.fold(
        (failure) => throw Exception(failure.toString()),
        (data) => data,
      );

      await _epgService.ensureFresh(playlistUrl: playlistUrl, force: force);

      setState(() {
        _loading = false;
        _playlistUrl = playlistUrl;
        _channels = channels;
        _currentChannel = current;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
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
    if (_loading) {
      return const _LiveEpgLoadingState();
    }

    if (_error != null) {
      return _LiveEpgErrorState(
        message: _error ?? '',
        onRetry: () => _load(force: true),
      );
    }

    if (_playlistUrl == null || _playlistUrl!.isEmpty || _channels.isEmpty) {
      return _LiveEpgEmptyState(
        onRetry: () => _load(force: true),
      );
    }

    return EpgTimelinePage(
      channels: _channels,
      playlistUrl: _playlistUrl,
      currentChannel: _currentChannel,
    );
  }
}

class _LiveEpgLoadingState extends StatelessWidget {
  const _LiveEpgLoadingState();

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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: const [
                  _ShimmerBar(width: 220, height: 22),
                  SizedBox(height: 12),
                  _ShimmerBar(width: double.infinity, height: 44),
                  SizedBox(height: 12),
                  Expanded(child: _EpgTimelineSkeleton()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveEpgErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LiveEpgErrorState({required this.message, required this.onRetry});

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

class _LiveEpgEmptyState extends StatelessWidget {
  final VoidCallback onRetry;

  const _LiveEpgEmptyState({required this.onRetry});

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
                            'No encontramos una playlist reciente. Selecciona una lista o configura el EPG para continuar.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(color: Colors.white54, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => context.go('/settings/epg'),
                                icon: const Icon(Icons.settings_rounded, size: 18),
                                label: Text('Ajustes EPG', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(color: CinematicColors.accent.withOpacity(0.5)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => context.go('/playlist'),
                                icon: const Icon(Icons.playlist_play_rounded, size: 18),
                                label: Text('Seleccionar playlist', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: CinematicColors.accent,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: onRetry,
                                icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
                                label: Text('Reintentar', style: GoogleFonts.montserrat(color: Colors.white70, fontWeight: FontWeight.w800)),
                              ),
                            ],
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
  }
}

class _EpgTimelineSkeleton extends StatelessWidget {
  const _EpgTimelineSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final leftWidth = constraints.maxWidth < 600 ? 180.0 : 260.0;
        return Row(
          children: [
            SizedBox(
              width: leftWidth,
              child: Column(
                children: List.generate(
                  6,
                  (index) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: _ShimmerRow(height: 56),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  const _ShimmerRow(height: 40),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: 6,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, __) => const _ShimmerRow(height: 56),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ShimmerBar extends StatelessWidget {
  final double width;
  final double height;

  const _ShimmerBar({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.08),
      highlightColor: Colors.white.withOpacity(0.18),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _ShimmerRow extends StatelessWidget {
  final double height;

  const _ShimmerRow({required this.height});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.08),
      highlightColor: Colors.white.withOpacity(0.18),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
