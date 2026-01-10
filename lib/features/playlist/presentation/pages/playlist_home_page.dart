import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class PlaylistHomePage extends StatelessWidget {
  final String playlistUrl;

  const PlaylistHomePage({super.key, required this.playlistUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D47A1), // Azul profundo
              Color(0xFF000000), // Negro
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. HEADER - Info de Usuario
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Bienvenido,",
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          "Usuario OmniStream",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.account_circle, color: Colors.white, size: 50),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 2. GRID DE BOTONES PRINCIPALES
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.all(20),
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1.1,
                  children: [
                    // LIVE TV
                    _MenuButton(
                      title: "LIVE TV",
                      icon: Icons.live_tv,
                      color1: Colors.blue.shade900,
                      color2: Colors.blue.shade500,
                      onTap: () => context.pushNamed('channels', extra: playlistUrl),
                    ),
                    // MOVIES
                    _MenuButton(
                      title: "MOVIES",
                      icon: Icons.movie_filter,
                      color1: Colors.orange.shade900,
                      color2: Colors.orange.shade500,
                      onTap: () => _showComingSoon(context, "Películas"),
                    ),
                    // SERIES
                    _MenuButton(
                      title: "SERIES",
                      icon: Icons.video_collection,
                      color1: Colors.purple.shade900,
                      color2: Colors.purple.shade500,
                      onTap: () => _showComingSoon(context, "Series"),
                    ),
                    // MULTI-SCREEN (Tu QuadView)
                    _MenuButton(
                      title: "MULTI-SCREEN",
                      icon: Icons.grid_view_rounded,
                      color1: Colors.teal.shade900,
                      color2: Colors.teal.shade500,
                      onTap: () => context.pushNamed('quad_view', extra: playlistUrl),
                    ),
                  ],
                ),
              ),

              // 3. BARRA INFERIOR DE AJUSTES
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _BottomAction(icon: Icons.settings, label: "Settings"),
                    _BottomAction(icon: Icons.account_box, label: "Account"),
                    _BottomAction(icon: Icons.refresh, label: "Refresh"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$feature estará disponible próximamente")),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color1;
  final Color color2;
  final VoidCallback onTap;

  const _MenuButton({
    required this.title,
    required this.icon,
    required this.color1,
    required this.color2,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(colors: [color1, color2], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [
            BoxShadow(color: color1.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 55),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BottomAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 28),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}