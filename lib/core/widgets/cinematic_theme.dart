import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CinematicColors {
  static const Color background = Colors.black;
  static const Color overlay = Colors.black54;
  static const Color glass = Color(0x1FFFFFFF); // Blanco muy transparente
  static const Color accent = Color(0xFF00A8E8); // Azul neón suave
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
}

class CinematicStyles {
  static TextStyle get title => GoogleFonts.montserrat(
    color: CinematicColors.textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    shadows: [const Shadow(color: Colors.black, blurRadius: 10)],
  );

  static TextStyle get subtitle => GoogleFonts.montserrat(
    color: CinematicColors.textSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get clock => GoogleFonts.shareTechMono(
    color: CinematicColors.textPrimary,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    shadows: [const Shadow(color: Colors.black, blurRadius: 8)],
  );
}