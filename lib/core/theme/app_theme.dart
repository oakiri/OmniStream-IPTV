import 'package:flutter/material.dart';

class AppTheme {
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF0A0E21),
    scaffoldBackgroundColor: const Color(0xFF0A0E21),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF0A0E21),
      secondary: Color(0xFF00E5FF),
      surface: Color.fromRGBO(10, 14, 33, 0.8),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0A0E21),
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: const Color.fromRGBO(10, 14, 33, 0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF00E5FF).withOpacity(0.2), width: 0.5),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color.fromRGBO(10, 14, 33, 0.8),
      selectedColor: const Color(0xFF00E5FF),
      labelStyle: const TextStyle(color: Colors.white),
      secondaryLabelStyle: const TextStyle(color: Colors.black),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: const Color(0xFF00E5FF).withOpacity(0.2), width: 0.5),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
  );
}
