import 'package:flutter/material.dart';
import 'cinematic_theme.dart';

class CinematicTopBar extends StatelessWidget {
  final String currentTime;
  final String? aspectRatioText; // NUEVO: Texto para el zoom (Normal, Zoom, Estirar)

  const CinematicTopBar({
    super.key, 
    required this.currentTime,
    this.aspectRatioText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
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
          // Lado Izquierdo: Logo y Título
          Row(
            children: [
              const Icon(Icons.live_tv, color: CinematicColors.accent),
              const SizedBox(width: 10),
              Text("OmniStream", style: CinematicStyles.title.copyWith(fontSize: 18)),
            ],
          ),

          // Lado Derecho: Zoom y Reloj
          Row(
            children: [
              // Indicador de Zoom (Solo se muestra si hay texto)
              if (aspectRatioText != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
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
                const SizedBox(width: 20), // Separación con el reloj
              ],

              // Reloj
              Text(currentTime, style: CinematicStyles.clock),
            ],
          ),
        ],
      ),
    );
  }
}