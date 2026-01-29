import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_theme.dart';

class LivePage extends StatelessWidget {
  const LivePage({super.key});

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
                  center: Alignment.topRight,
                  radius: 1.5,
                  colors: [Color(0xFF181818), Colors.black],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.live_tv_rounded, size: 64, color: CinematicColors.accent.withOpacity(0.9)),
                  const SizedBox(height: 16),
                  Text('TV en Vivo / EPG', style: GoogleFonts.audiowide(color: Colors.white, fontSize: 22)),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Aquí irá el módulo 3: pantalla EPG híbrida con mini-player + grid.',
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
