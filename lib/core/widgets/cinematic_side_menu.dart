import 'dart:ui';
import 'package:flutter/material.dart';
// Asegúrate de tener este archivo o quita el import si usas colores hardcodeados
import 'cinematic_theme.dart'; 

class CinematicSideMenu extends StatelessWidget {
  final VoidCallback onEpgTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onAspectRatioTap; // Callback para el Zoom

  const CinematicSideMenu({
    super.key,
    required this.onEpgTap,
    required this.onSettingsTap,
    required this.onAspectRatioTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black87, Colors.transparent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _MenuButton(icon: Icons.dvr, label: "EPG", onTap: onEpgTap),
          const SizedBox(height: 20),
          // Botón de Zoom recuperado
          _MenuButton(icon: Icons.aspect_ratio, label: "Zoom", onTap: onAspectRatioTap),
          const SizedBox(height: 20),
          _MenuButton(icon: Icons.settings, label: "Ajustes", onTap: onSettingsTap),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}