import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_theme.dart';

class VodPage extends StatelessWidget {
  const VodPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.6,
                  colors: [Color(0xFF1A1A1A), Colors.black],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.movie_rounded, size: 64, color: CinematicColors.accent.withOpacity(0.9)),
                  const SizedBox(height: 16),
                  Text('VOD', style: GoogleFonts.audiowide(color: Colors.white, fontSize: 22)),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Reservado para la fase futura: catálogos, carátulas y detalles cinematic.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(color: Colors.white60, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
