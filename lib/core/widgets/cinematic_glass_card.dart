import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/cinematic_theme.dart';

class CinematicGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final double blurSigma;
  final double opacity;
  final Color borderColor;

  const CinematicGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.blurSigma = 18,
    this.opacity = 0.68,
    this.borderColor = CinematicColors.stroke,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: CinematicTheme.surfaceGradient(opacity: opacity),
            borderRadius: borderRadius,
            border: Border.all(color: borderColor, width: 0.8),
            boxShadow: CinematicTheme.glassShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}
