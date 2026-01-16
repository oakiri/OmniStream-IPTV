import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class PlaylistHomePage extends StatelessWidget {
  final String playlistUrl;

  const PlaylistHomePage({super.key, required this.playlistUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Para que el gradiente suba hasta arriba
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.go('/dashboard'), // Volver a mis listas
        ),
      ),
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
                          style: GoogleFonts.poppins(
                              color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          "Usuario OmniStream",
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                      ],
                    ),
                    const CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. GRID PRINCIPAL (4 Botones grandes)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.1,
                    children: [
                      _MenuCard(
                        title: "LIVE TV",
                        icon: Icons.live_tv,
                        color1: const Color(0xFF42A5F5),
                        color2: const Color(0xFF1565C0),
                        onTap: () {
                          // Navegar a la parrilla de canales pasando la URL
                          context.pushNamed('channels', extra: playlistUrl);
                        },
                      ),
                      _MenuCard(
                        title: "MOVIES",
                        icon: Icons.movie,
                        color1: const Color(0xFFEF5350),
                        color2: const Color(0xFFC62828),
                        onTap: () {
                          // Futura implementación
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Próximamente: Películas")));
                        },
                      ),
                      _MenuCard(
                        title: "SERIES",
                        icon: Icons.tv,
                        color1: const Color(0xFFFFA726),
                        color2: const Color(0xFFEF6C00),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Próximamente: Series")));
                        },
                      ),
                      _MenuCard(
                        title: "MULTI-SCREEN",
                        icon: Icons.grid_view,
                        color1: const Color(0xFF66BB6A),
                        color2: const Color(0xFF2E7D32),
                        onTap: () {
                          // Navegar a la vista múltiple
                          context.push('/quad_view');
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // 3. BARRA INFERIOR (Ajustes, EPG, etc)
              Container(
                height: 80,
                color: Colors.black45,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _BottomAction(icon: Icons.dvr, label: "Grabaciones"),
                    _BottomAction(icon: Icons.speed, label: "Test Velocidad"),
                    _BottomAction(icon: Icons.settings, label: "Ajustes"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color1;
  final Color color2;
  final VoidCallback onTap;

  const _MenuCard({
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
              colors: [color1, color2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          boxShadow: [
            BoxShadow(
                color: color1.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 50),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
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
        Icon(icon, color: Colors.white70),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}
