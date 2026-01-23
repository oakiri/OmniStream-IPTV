import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';
import 'package:omnistream_iptv/core/theme/app_theme.dart'; // Tu tema base
import 'cinematic_theme.dart';

class CinematicGlassCard extends StatelessWidget {
  final Channel channel;
  final bool isPlaying;
  final VoidCallback onPlayPause;

  const CinematicGlassCard({
    super.key,
    required this.channel,
    required this.isPlaying,
    required this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: CinematicColors.glass,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              // Logo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                  image: channel.logoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(channel.logoUrl!),
                          fit: BoxFit.contain,
                        )
                      : null,
                ),
                child: channel.logoUrl == null
                    ? const Icon(Icons.tv, color: Colors.white54)
                    : null,
              ),
              const SizedBox(width: 16),
              // Textos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      channel.name,
                      style: CinematicStyles.title.copyWith(fontSize: 20),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "LIVE • ${channel.group ?? 'General'}",
                      style: CinematicStyles.subtitle,
                    ),
                  ],
                ),
              ),
              // Botón Play/Pause grande
              IconButton(
                onPressed: onPlayPause,
                iconSize: 48,
                color: CinematicColors.accent,
                icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
              ),
            ],
          ),
        ),
      ),
    );
  }
}