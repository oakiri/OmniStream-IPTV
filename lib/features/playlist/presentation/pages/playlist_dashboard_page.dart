import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
// NOTE: Use a prefix to avoid a name clash with Flutter's dart:ui TextDirection.
import 'package:intl/intl.dart' as intl;

import 'package:omnistream_iptv/injection_container.dart';
import 'package:omnistream_iptv/core/storage/recent_playback_store.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_theme.dart';
import 'package:omnistream_iptv/features/channels/presentation/widgets/channel_logo.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/playlist_profile.dart';
import 'package:omnistream_iptv/features/playlist/presentation/bloc/playlist_profile_bloc.dart';

class PlaylistDashboardPage extends StatefulWidget {
  const PlaylistDashboardPage({super.key});

  @override
  State<PlaylistDashboardPage> createState() => _PlaylistDashboardPageState();
}

class _PlaylistDashboardPageState extends State<PlaylistDashboardPage> {

  // WOW palette (used by premium gold/green UI). Keeping it local avoids missing getters in hotfixes.
  Color get wowGold => const Color(0xFFD6B35A); // Gold accent
  Color get wowGreen => const Color(0xFF2ECC71); // Green accent
  void _openAddPlaylistWizard() {
    // Wizard full-screen (fuera del shell) => evita problemas de teclado/rotación.
    context.pushNamed('addPlaylist');
  }

  void _showDeleteConfirm(PlaylistProfile profile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Eliminar lista',
          style: GoogleFonts.montserrat(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        content: Text(
          '¿Seguro que quieres borrar "${profile.name}"?',
          style: GoogleFonts.montserrat(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCELAR', style: GoogleFonts.montserrat(color: Colors.white38, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () {
              context.read<PlaylistProfileBloc>().add(DeleteProfileEvent(profile.id));
              Navigator.pop(ctx);
            },
            child: Text(
              'BORRAR',
              style: GoogleFonts.montserrat(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTv = MediaQuery.of(context).navigationMode == NavigationMode.directional;
    final sidePadding = MediaQuery.of(context).size.width > 600 ? 60.0 : 20.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _BackgroundGlow(),
          SafeArea(
            child: BlocBuilder<PlaylistProfileBloc, PlaylistProfileState>(
              builder: (context, state) {
                final slivers = <Widget>[
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(sidePadding, 32, sidePadding, 14),
                    sliver: SliverToBoxAdapter(child: _buildHeader(isTv: isTv)),
                  ),
                ];

                if (state is PlaylistProfileLoading) {
                  slivers.add(
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: sidePadding),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => const Padding(
                            padding: EdgeInsets.only(bottom: 14),
                            child: _Shimmer(child: _SkeletonCard()),
                          ),
                          childCount: 7,
                        ),
                      ),
                    ),
                  );
                } else if (state is PlaylistProfileError) {
                  slivers.add(
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          state.message,
                          style: GoogleFonts.montserrat(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                } else if (state is PlaylistProfilesLoaded) {
                  if (state.profiles.isEmpty) {
                    slivers.add(
                      SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState()),
                    );
                  } else {
                    final profiles = [...state.profiles];

                    slivers.add(
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(sidePadding, 6, sidePadding, 14),
                        sliver: SliverToBoxAdapter(
                          child: FutureBuilder<RecentChannelPlayback?>(
                            future: sl<RecentPlaybackStore>().loadLastChannel(),
                            builder: (context, snap) {
                              final last = snap.data;
                              if (last == null) return const SizedBox.shrink();

                              final match = profiles.where((p) => (p.url.trim() == last.playlistUrl.trim())).toList();
                              final playlistName = match.isNotEmpty ? match.first.name : null;

                              return _ContinueWatchingChannelBanner(
                                last: last,
                                playlistName: playlistName,
                                onResume: () {
                                  if (last.playlistUrl.trim().isNotEmpty) {
                                    context.pushNamed(
                                      'channels',
                                      extra: {
                                        'playlistUrl': last.playlistUrl,
                                        'initialChannelId': last.channelId,
                                        'initialChannelUrl': last.channelUrl,
                                        'autoPlay': true,
                                      },
                                    );
                                  } else {
                                    context.pushNamed(
                                      'player',
                                      extra: {
                                        'channel': last.toChannel(),
                                        'channels': <dynamic>[],
                                        'playlistUrl': null,
                                      },
                                    );
                                  }
                                },
                                onGoToList: last.playlistUrl.trim().isEmpty
                                    ? null
                                    : () => context.pushNamed(
                                          'channels',
                                          // Importante: NO pasamos initialChannelId/Url aquí para
                                          // que la grid no marque/ressalte el último canal.
                                          extra: last.playlistUrl,
                                        ),
                              );
                            },
                          ),
                        ),
                      ),
                    );

                    slivers.add(
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: sidePadding),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final p = profiles[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _NetflixPlaylistCard(
                                  profile: p,
                                  isTv: isTv,
                                  onTap: () => context.pushNamed('channels', extra: p.url),
                                  onEdit: () => context.pushNamed('addPlaylist', extra: p),
                                  onDelete: () => _showDeleteConfirm(p),
                                ),
                              );
                            },
                            childCount: profiles.length,
                          ),
                        ),
                      ),
                    );
                  }
                }

                slivers.add(const SliverPadding(padding: EdgeInsets.only(bottom: 110)));

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: slivers,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _buildCinematicFAB(),
    );
  }

  Widget _buildCinematicFAB() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: CinematicColors.accent.withOpacity(0.6), blurRadius: 20),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _openAddPlaylistWizard,
        backgroundColor: wowGold,
        elevation: 0,
        child: const Icon(Icons.add_link_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildHeader({required bool isTv}) {
    final date = intl.DateFormat('EEEE, d MMMM').format(DateTime.now()).toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          date,
          style: GoogleFonts.montserrat(
            color: Colors.white54,
            fontSize: 11,
            letterSpacing: 3.0,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Mis listas',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: isTv ? 30 : 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.playlist_add_check_circle, size: 80, color: Colors.white.withOpacity(0.10)),
            const SizedBox(height: 18),
            Text('Tu espacio está vacío', style: GoogleFonts.montserrat(color: Colors.white60, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              'Añade una lista M3U o Xtream para comenzar.',
              style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _openAddPlaylistWizard,
              icon: const Icon(Icons.add_link_rounded),
              label: Text('Añadir playlist', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -150,
          right: -150,
          child: Container(
            width: 420,
            height: 420,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  CinematicColors.accent.withOpacity(0.16),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -180,
          left: -180,
          child: Container(
            width: 520,
            height: 520,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  CinematicColors.accent.withOpacity(0.10),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContinueWatchingChannelBanner extends StatefulWidget {
  const _ContinueWatchingChannelBanner({
    required this.last,
    required this.playlistName,
    required this.onResume,
    required this.onGoToList,
  });

  final RecentChannelPlayback last;
  final String? playlistName;
  final VoidCallback onResume;
  final VoidCallback? onGoToList;

  @override
  State<_ContinueWatchingChannelBanner> createState() => _ContinueWatchingChannelBannerState();
}

class _ContinueWatchingChannelBannerState extends State<_ContinueWatchingChannelBanner> {
  bool _focused = false;
  bool _hovered = false;

  bool get _useBlur => !kIsWeb && defaultTargetPlatform != TargetPlatform.android;

  @override
  Widget build(BuildContext context) {
    final active = _focused || _hovered;

    // WOW palette (gold/green) para el banner de "Continuar viendo"
    const wowGold = Color(0xFFD8B45B);
    const wowGreen = Color(0xFF2EE6A1);

    final subtitle = <String>[
      if ((widget.last.group ?? '').trim().isNotEmpty) widget.last.group!.trim(),
      if ((widget.playlistName ?? '').trim().isNotEmpty) widget.playlistName!.trim(),
    ].join(' • ');

    final actionRow = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ElevatedButton.icon(
          onPressed: widget.onResume,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text('Reanudar', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900)),
          style: ElevatedButton.styleFrom(
            backgroundColor: wowGold,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
        OutlinedButton.icon(
          onPressed: widget.onGoToList,
          icon: const Icon(Icons.list_alt_rounded),
          label: Text('Ir a lista', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            side: BorderSide(color: wowGold.withOpacity(0.45)),
          ),
        ),
      ],
    );

    final inner = Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          _ChannelThumb(url: widget.last.logoUrl),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Continuar viendo',
                  style: GoogleFonts.montserrat(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.last.channelName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                if (subtitle.trim().isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600),
                  )
                else
                  Text(
                    'Último visto: ${intl.DateFormat('dd/MM HH:mm').format(widget.last.lastSeenAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                const SizedBox(height: 14),
                actionRow,
              ],
            ),
          ),
        ],
      ),
    );

    final content = AnimatedContainer(

      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(2.2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            wowGold.withOpacity(active ? 0.95 : 0.55),
            wowGreen.withOpacity(active ? 0.85 : 0.45),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          if (active) BoxShadow(color: wowGold.withOpacity(0.20), blurRadius: 34, spreadRadius: 1),
          if (active) BoxShadow(color: wowGreen.withOpacity(0.16), blurRadius: 30),
          BoxShadow(color: Colors.black.withOpacity(0.55), blurRadius: 28, offset: const Offset(0, 16)),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1B1B1B).withOpacity(0.88),
              const Color(0xFF101010).withOpacity(0.92),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Stack(
          children: [
            // Acentos diagonales tipo "premium" (sutiles)
            Positioned(
              left: -44,
              top: -44,
              child: Transform.rotate(
                angle: 0.55,
                child: Container(
                  width: 180,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [wowGreen.withOpacity(active ? 0.22 : 0.14), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -56,
              bottom: -56,
              child: Transform.rotate(
                angle: 0.55,
                child: Container(
                  width: 200,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [wowGold.withOpacity(active ? 0.22 : 0.14), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
            inner,
          ],
        ),
      ),
    );

    return FocusableActionDetector(

      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        scale: active ? 1.01 : 1.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: _useBlur
              ? BackdropFilter(filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: content)
              : content,
        ),
      ),
    );
  }
}

class _ChannelThumb extends StatelessWidget {
  const _ChannelThumb({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    // WOW: marco gold/green pero manteniendo el "tile" blanco del logo como en el grid de canales.
    const wowGold = Color(0xFFD8B45B);
    const wowGreen = Color(0xFF2EE6A1);

    return Container(
      width: 66,
      height: 66,
      padding: const EdgeInsets.all(2.2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [wowGold.withOpacity(0.85), wowGreen.withOpacity(0.75)],
        ),
        boxShadow: [
          BoxShadow(color: wowGold.withOpacity(0.10), blurRadius: 18, offset: const Offset(0, 8)),
          BoxShadow(color: wowGreen.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: ChannelLogo(url: url, width: 48, height: 48),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NetflixPlaylistCard extends StatefulWidget {
  const _NetflixPlaylistCard({
    required this.profile,
    required this.isTv,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final PlaylistProfile profile;
  final bool isTv;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_NetflixPlaylistCard> createState() => _NetflixPlaylistCardState();
}

class _NetflixPlaylistCardState extends State<_NetflixPlaylistCard> {
  bool _focused = false;
  bool _hovered = false;

  bool get _useBlur => !kIsWeb && defaultTargetPlatform != TargetPlatform.android;

  @override
  Widget build(BuildContext context) {
    final active = _focused || _hovered;
    final badge = _playlistStatus(widget.profile.expirationDate);

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: active ? CinematicColors.accent.withOpacity(0.55) : Colors.white.withOpacity(0.12)),
        boxShadow: [
          if (active) BoxShadow(color: CinematicColors.accent.withOpacity(0.22), blurRadius: 26),
          BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 22, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: _StatusBadge(status: badge),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CardThumb(type: widget.profile.type),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: widget.isTv ? 18 : 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.profile.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    _MetaRow(lastUsed: widget.profile.lastUsed),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.55)),
                color: const Color(0xFF151515),
                onSelected: (value) {
                  if (value == 'edit') widget.onEdit();
                  if (value == 'delete') widget.onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [Icon(Icons.edit_rounded, size: 18), SizedBox(width: 10), Text('Editar')]),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18), SizedBox(width: 10), Text('Eliminar')]),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          scale: active ? 1.015 : 1.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _useBlur ? BackdropFilter(filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: content) : content,
          ),
        ),
      ),
    );
  }
}

class _CardThumb extends StatelessWidget {
  const _CardThumb({required this.type});

  final String? type;

  @override
  Widget build(BuildContext context) {
    // Más "WOW": iconos más cercanos a lo que representa cada lista.
    final icon = (type ?? '').toLowerCase().contains('xtream') ? Icons.flash_on_rounded : Icons.live_tv_rounded;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CinematicColors.accent.withOpacity(0.35),
            Colors.white.withOpacity(0.06),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Icon(icon, color: Colors.white.withOpacity(0.95), size: 26),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.lastUsed});

  final DateTime? lastUsed;

  @override
  Widget build(BuildContext context) {
    final text = (lastUsed == null)
        ? 'Sin uso reciente'
        : 'Último uso: ${intl.DateFormat('dd/MM/yyyy').format(lastUsed!)}';

    return Row(
      children: [
        Icon(Icons.history_rounded, size: 14, color: Colors.white.withOpacity(0.55)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

enum _PlaylistBadgeStatus { active, expiringSoon, expired }

_PlaylistBadgeStatus _playlistStatus(DateTime? expirationDate) {
  if (expirationDate == null) return _PlaylistBadgeStatus.active;
  final now = DateTime.now();
  if (expirationDate.isBefore(now)) return _PlaylistBadgeStatus.expired;
  final days = expirationDate.difference(now).inDays;
  if (days <= 7) return _PlaylistBadgeStatus.expiringSoon;
  return _PlaylistBadgeStatus.active;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _PlaylistBadgeStatus status;

  @override
  Widget build(BuildContext context) {
    final (text, bg) = switch (status) {
      _PlaylistBadgeStatus.active => ('ACTIVO', Colors.white.withOpacity(0.12)),
      _PlaylistBadgeStatus.expiringSoon => ('CADUCA PRONTO', Colors.orange.withOpacity(0.22)),
      _PlaylistBadgeStatus.expired => ('CADUCADA', Colors.redAccent.withOpacity(0.22)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          color: Colors.white.withOpacity(0.92),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});

  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value; // 0..1
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            final dx = rect.width * (t * 2 - 1); // -w..+w
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white.withOpacity(0.06),
                Colors.white.withOpacity(0.16),
                Colors.white.withOpacity(0.06),
              ],
              stops: const [0.2, 0.5, 0.8],
              transform: _SlidingGradientTransform(dx: dx),
            ).createShader(rect);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.dx});
  final double dx;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, 0, 0);
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 180,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const Spacer(),
                Container(
                  height: 12,
                  width: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}