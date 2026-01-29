import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_theme.dart';

/// Main persistent shell for the app.
///
/// Goals:
/// - 1 source of truth: the Shell index comes from GoRouter's StatefulNavigationShell.
/// - Responsive: BottomNav on mobile, SideRail on tablets/TV.
/// - No overlay menus that intercept taps / cause solapes.
class MainShellPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const MainShellPage({super.key, required this.navigationShell});

  void _go(int index) {
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Tablet/TV breakpoint.
        // En móviles en horizontal (y especialmente con el teclado abierto),
        // usar NavigationRail provoca overflows (RenderFlex overflowed) y layouts rotos.
        // Por eso, solo activamos el modo "...Large" si el dispositivo parece tablet/TV
        // (shortestSide >= 600) y además no hay teclado en pantalla.
        final mq = MediaQuery.of(context);
        final shortestSide = mq.size.shortestSide;
        final keyboardOpen = mq.viewInsets.bottom > 0;

        final isLarge = !keyboardOpen && constraints.maxWidth >= 820 && shortestSide >= 600;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topRight,
                      radius: 1.6,
                      colors: [Color(0xFF151515), Colors.black],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: isLarge
                    ? Row(
                        children: [
                          _CinematicRail(
                            selectedIndex: navigationShell.currentIndex,
                            onSelect: _go,
                          ),
                          const VerticalDivider(width: 1, thickness: 1, color: Color(0x14000000)),
                          Expanded(child: navigationShell),
                        ],
                      )
                    : navigationShell,
              ),
            ],
          ),
          bottomNavigationBar: isLarge
              ? null
              : _CinematicBottomBar(
                  selectedIndex: navigationShell.currentIndex,
                  onSelect: _go,
                ),
        );
      },
    );
  }
}

class _CinematicBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _CinematicBottomBar({required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelect,
      height: 76,
      backgroundColor: const Color(0xFF131313),
      indicatorColor: CinematicColors.accent.withOpacity(0.16),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Listas',
        ),
        NavigationDestination(
          icon: Icon(Icons.live_tv_outlined),
          selectedIcon: Icon(Icons.live_tv_rounded),
          label: 'En vivo',
        ),
        NavigationDestination(
          icon: Icon(Icons.movie_outlined),
          selectedIcon: Icon(Icons.movie_rounded),
          label: 'VOD',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: 'Ajustes',
        ),
      ],
    );
  }
}

class _CinematicRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _CinematicRail({required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F).withOpacity(0.85),
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: CinematicColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: CinematicColors.accent.withOpacity(0.25)),
                  ),
                  child: const Icon(Icons.tv_rounded, color: CinematicColors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('OMNISTREAM', style: GoogleFonts.audiowide(color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text('IPTV', style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Scrollbar(
              child: SingleChildScrollView(
                child: NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelect,
              backgroundColor: Colors.transparent,
              useIndicator: true,
              indicatorColor: CinematicColors.accent.withOpacity(0.16),
              selectedIconTheme: const IconThemeData(color: CinematicColors.accent),
              unselectedIconTheme: const IconThemeData(color: Colors.white54),
              selectedLabelTextStyle: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w800),
              unselectedLabelTextStyle: GoogleFonts.montserrat(color: Colors.white54, fontWeight: FontWeight.w700),
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: Text('Listas'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.live_tv_outlined),
                  selectedIcon: Icon(Icons.live_tv_rounded),
                  label: Text('En vivo'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.movie_outlined),
                  selectedIcon: Icon(Icons.movie_rounded),
                  label: Text('VOD'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: Text('Ajustes'),
                ),
              ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFF2A2A2A),
                    child: Icon(Icons.person, color: Colors.white70, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mi usuario', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('Gratis', style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 11)),
                      ],
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
