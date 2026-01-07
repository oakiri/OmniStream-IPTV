import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      primaryColor: Colors.deepPurple,
      colorScheme: const ColorScheme.dark(
        primary: Colors.deepPurple,
        secondary: Colors.deepPurpleAccent,
        surface: Color(0xFF1E1E1E),
        onSurface: Colors.white,
      ),
      textTheme: GoogleFonts.robotoTextTheme().apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E).withOpacity(0.8),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF121212),
        elevation: 0,
      ),
    );
  }
}
