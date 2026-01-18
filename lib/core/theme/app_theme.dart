import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'cinematic_theme.dart';

class AppTheme {
  // Colores estilo "Smarters"
  static const Color primaryColor = CinematicColors.accent;
  static const Color accentColor = CinematicColors.accentSoft;
  static const Color backgroundColor = CinematicColors.background;
  static const Color surfaceColor = CinematicColors.backgroundElevated;
  static const Color errorColor = Color(0xFFCF6679);

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,

    // Configuración de Textos (Todo blanco por defecto)
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),

    // COMENTADO TEMPORALMENTE PARA EVITAR ERROR DE VERSIÓN
    // cardTheme: CardTheme(
    //   color: surfaceColor,
    //   elevation: 4,
    //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    // ),

    // Configuración de Inputs (Buscador y Formularios)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      hintStyle: const TextStyle(color: Colors.grey),
      labelStyle: const TextStyle(color: Colors.white70),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentColor, width: 2),
      ),
    ),

    // Configuración de la AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundColor,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    // COMENTADO TEMPORALMENTE PARA EVITAR ERROR DE VERSIÓN
    // dialogTheme: const DialogTheme(
    //   backgroundColor: surfaceColor,
    //   titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
    //   contentTextStyle: TextStyle(color: Colors.white70, fontSize: 16),
    // ),
  );
}
