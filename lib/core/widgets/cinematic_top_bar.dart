import 'package:flutter/material.dart';
import 'cinematic_theme.dart';

class CinematicTopBar extends StatelessWidget {
  final String currentTime;
  final String? aspectRatioText; // NUEVO: Texto para el zoom (Normal, Zoom, Estirar)
  final VoidCallback? onBack;

  const CinematicTopBar({
    super.key, 
    required this.currentTime,
    this.aspectRatioText,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black87, Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Lado Izquierdo: Back + Logo + Título
            Row(
              children: [
                if (onBack != null) ...[
                  InkWell(
                    onTap: onBack,
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                Image.asset('assets/branding/vivid_mark.png', width: 26, height: 26, filterQuality: FilterQuality.high),
                const SizedBox(width: 10),
                Text(
                  "VIVID",
                  style: CinematicStyles.title.copyWith(
                    fontSize: 18,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),

            // Lado Derecho: Zoom y Reloj
            Row(
              children: [
                if (aspectRatioText != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.aspect_ratio, color: Colors.white70, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          aspectRatioText!.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Text(currentTime, style: CinematicStyles.clock),
              ],
            ),
          ],
        ),
      ),
    );
  }
}