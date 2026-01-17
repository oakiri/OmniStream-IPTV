import 'package:flutter/material.dart';

import '../theme/cinematic_theme.dart';

class CinematicPlatformBadges extends StatelessWidget {
  final List<String> labels;

  const CinematicPlatformBadges({
    super.key,
    required this.labels,
  });

  factory CinematicPlatformBadges.placeholder() {
    return const CinematicPlatformBadges(
      labels: ['Plataforma Gratis', 'Premium', 'HD+'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: labels
          .map(
            (label) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: CinematicColors.stroke),
                color: CinematicColors.backgroundElevated.withOpacity(0.5),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: CinematicColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
