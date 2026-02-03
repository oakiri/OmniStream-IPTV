import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omnistream_iptv/core/epg/epg_models.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_theme.dart';
import 'package:omnistream_iptv/features/channels/presentation/widgets/channel_logo.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';

class CinematicGlassCard extends StatelessWidget {
  final Channel channel;
  final bool isPlaying;
  final VoidCallback onPlayPause;

  /// EPG (NOW / NEXT) para mostrarlo dentro de la misma tarjeta (junto a la info del canal).
  final EpgNowNext? nowNext;
  final bool epgLoading;
  final VoidCallback? onEpgTap;

  const CinematicGlassCard({
    super.key,
    required this.channel,
    required this.isPlaying,
    required this.onPlayPause,
    this.nowNext,
    this.epgLoading = false,
    this.onEpgTap,
  });

  String _fmtTime(DateTime dt) => DateFormat('HH:mm').format(dt.toLocal());

  double? _progress(EpgProgram now) {
    final nowUtc = DateTime.now().toUtc();
    if (nowUtc.isBefore(now.start) || nowUtc.isAfter(now.stop)) return null;
    final total = now.stop.difference(now.start).inSeconds;
    if (total <= 0) return null;
    return (nowUtc.difference(now.start).inSeconds / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final nn = nowNext;
    final now = nn?.now;
    final next = nn?.next;

    final progress = (now != null) ? _progress(now) : null;

    // Siempre mostramos el bloque (aunque sea "Sin EPG") para que quede integrado en el card.
    final showEpgBlock = true;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: CinematicColors.glass,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                  color: Colors.white.withOpacity(0.04),
                ),
                clipBehavior: Clip.antiAlias,
                child: ChannelLogo(url: channel.logoUrl),
              ),
              const SizedBox(width: 16),

              // Texto + EPG
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      channel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CinematicStyles.title.copyWith(
                        fontSize: 22,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'LIVE • ${(channel.group ?? channel.groupTitle ?? '').isEmpty ? '—' : (channel.group ?? channel.groupTitle)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CinematicStyles.subtitle.copyWith(
                        fontSize: 13,
                        color: Colors.white70,
                        letterSpacing: 0.8,
                      ),
                    ),

                    if (showEpgBlock) ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // mini botón EPG (WOW)
                          if (onEpgTap != null)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: onEpgTap,
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: CinematicColors.accent.withOpacity(0.14),
                                    border: Border.all(color: CinematicColors.accent.withOpacity(0.32)),
                                  ),
                                  child: const Icon(Icons.view_timeline_rounded, size: 20, color: CinematicColors.accent),
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 38, height: 38),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // NOW
                                Row(
                                  children: [
                                    const _Pill(text: 'NOW'),
                                    const SizedBox(width: 8),
                                    if (now != null)
                                      Text(
                                        _fmtTime(now.start),
                                        style: CinematicStyles.subtitle.copyWith(fontSize: 12, color: Colors.white60),
                                      ),
                                    if (now != null) const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        now?.title ?? (epgLoading ? 'Cargando EPG…' : 'Sin EPG'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: CinematicStyles.title.copyWith(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                if (progress != null) ...[
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 4,
                                      backgroundColor: Colors.white.withOpacity(0.06),
                                      valueColor: const AlwaysStoppedAnimation(CinematicColors.accent),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),

                                // NEXT
                                Row(
                                  children: [
                                    const _Pill(text: 'NEXT'),
                                    const SizedBox(width: 8),
                                    if (next != null)
                                      Text(
                                        _fmtTime(next.start),
                                        style: CinematicStyles.subtitle.copyWith(fontSize: 12, color: Colors.white60),
                                      ),
                                    if (next != null) const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        next?.title ?? '—',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: CinematicStyles.subtitle.copyWith(fontSize: 13, color: Colors.white70),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Play/Pause
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPlayPause,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: CinematicColors.accent,
                      boxShadow: [
                        BoxShadow(
                          color: CinematicColors.accent.withOpacity(0.30),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 30,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;

  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Text(
        text,
        style: CinematicStyles.subtitle.copyWith(
          fontWeight: FontWeight.w900,
          fontSize: 10,
          color: Colors.white70,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
