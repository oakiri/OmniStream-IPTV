import 'package:flutter/material.dart';

class CinematicColors {
  static const Color background = Color(0xFF0A0D14);
  static const Color backgroundDeep = Color(0xFF07080F);
  static const Color backgroundElevated = Color(0xFF14182B);
  static const Color accent = Color(0xFF6D5BFF);
  static const Color accentSoft = Color(0xFF3BC4FF);
  static const Color textPrimary = Color(0xFFF5F7FF);
  static const Color textMuted = Color(0xFFB9C0D4);
  static const Color stroke = Color(0x33FFFFFF);
  static const Color glass = Color(0xFF171B2D);
  static const Color glow = Color(0xFF6F7CFF);
}

class CinematicTheme {
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0B0E18),
      Color(0xFF151A2F),
      Color(0xFF0A0D14),
    ],
  );

  static LinearGradient surfaceGradient({double opacity = 0.68}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        CinematicColors.glass.withOpacity(opacity),
        const Color(0xFF1D2340).withOpacity(opacity),
      ],
    );
  }

  static List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.35),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];
}
