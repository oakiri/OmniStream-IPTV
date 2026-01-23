import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_theme.dart';

class MainShellPage extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainShellPage({super.key, required this.navigationShell});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> with SingleTickerProviderStateMixin {
  bool _isExpanded = false; 
  late AnimationController _animController;
  late Animation<double> _blurAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _blurAnimation = Tween<double>(begin: 0.0, end: 5.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) _animController.forward(); else _animController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double safePaddingLeft = MediaQuery.of(context).padding.left;
    
    // Ancho total incluyendo el notch
    final double sidebarWidth = (_isExpanded ? 260.0 : 80.0) + safePaddingLeft;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // CAPA 1: CONTENIDO (LISTAS Y DASHBOARD)
          Positioned.fill(
            child: GestureDetector(
              // IMPORTANTE: Esto permite que los clics pasen a las listas si el menú está cerrado
              onTap: () { 
                if (_isExpanded) _toggleMenu(); 
              },
              behavior: _isExpanded ? HitTestBehavior.opaque : HitTestBehavior.translucent,
              child: widget.navigationShell,
            ),
          ),

          // CAPA 2: OSCURECIMIENTO (Solo visible si menú abierto)
          if (_isExpanded)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleMenu,
                child: AnimatedBuilder(
                  animation: _blurAnimation,
                  builder: (context, child) => BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: _blurAnimation.value, sigmaY: _blurAnimation.value),
                    child: Container(color: Colors.black.withOpacity(0.4 * _animController.value)),
                  ),
                ),
              ),
            ),

          // CAPA 3: BARRA LATERAL
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            left: 0, top: 0, bottom: 0,
            width: sidebarWidth,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(topRight: Radius.circular(24), bottomRight: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212).withOpacity(0.96), 
                    border: const Border(right: BorderSide(color: Colors.white10, width: 1)),
                    boxShadow: _isExpanded ? [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40, offset: const Offset(10, 0))] : [],
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(left: safePaddingLeft),
                    child: SafeArea(
                      left: false, 
                      right: false,
                      // CORRECCIÓN: bottom: true para respetar la barra de gestos/botones
                      bottom: true, 
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Si la altura disponible (ya restada la barra del sistema) es poca, scroll.
                          bool useScrollView = constraints.maxHeight < 400;

                          if (useScrollView) {
                            return SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              child: Column(
                                children: [
                                  _buildHeader(compact: true),
                                  const SizedBox(height: 10),
                                  _buildMenuOptions(compact: true),
                                  const SizedBox(height: 10),
                                  _buildUserFooter(),
                                ],
                              ),
                            );
                          } else {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                              child: Column(
                                children: [
                                  _buildHeader(compact: false),
                                  const SizedBox(height: 30),
                                  _buildMenuOptions(compact: false),
                                  const Spacer(), 
                                  _buildUserFooter(),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ... (El resto de widgets _buildHeader, _buildMenuOptions, etc. son idénticos a la versión anterior)
  // Asegúrate de copiar los widgets auxiliares (_MenuToggleButton, etc.) de la respuesta anterior
  
  Widget _buildHeader({required bool compact}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 5 : 10),
      child: Row(
        mainAxisAlignment: _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          _MenuToggleButton(isExpanded: _isExpanded, onTap: _toggleMenu),
          if (_isExpanded) ...[
            const SizedBox(width: 15),
            Expanded(
              child: AnimatedOpacity(
                opacity: _isExpanded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Text("OmniStream", style: GoogleFonts.audiowide(color: Colors.white, fontSize: 18), overflow: TextOverflow.ellipsis, maxLines: 1),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildMenuOptions({required bool compact}) {
    double spacing = compact ? 4 : 8;
    return Column(
      children: [
        _GlowingMenuItem(icon: Icons.dashboard_rounded, label: "Inicio", isSelected: widget.navigationShell.currentIndex == 0, isExpanded: _isExpanded, onTap: () => _navigateTo(0)),
        SizedBox(height: spacing),
        _GlowingMenuItem(icon: Icons.live_tv_rounded, label: "TV en Vivo", isSelected: widget.navigationShell.currentIndex == 1, isExpanded: _isExpanded, onTap: () => _navigateTo(1)),
        SizedBox(height: spacing),
        _GlowingMenuItem(icon: Icons.movie_rounded, label: "Películas", isSelected: widget.navigationShell.currentIndex == 2, isExpanded: _isExpanded, onTap: () => _navigateTo(2)),
        SizedBox(height: spacing * 2),
        _GlowingMenuItem(icon: Icons.settings_rounded, label: "Ajustes", isSelected: widget.navigationShell.currentIndex == 3, isExpanded: _isExpanded, onTap: () => _navigateTo(3)),
      ],
    );
  }

  Widget _buildUserFooter() {
    return _UserFooter(isExpanded: _isExpanded, onTap: () {});
  }

  void _navigateTo(int index) {
    widget.navigationShell.goBranch(index, initialLocation: index == widget.navigationShell.currentIndex);
  }
}

// --- WIDGETS AUXILIARES (Indispensables) ---

class _MenuToggleButton extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onTap;
  const _MenuToggleButton({required this.isExpanded, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container( 
          width: 44, height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: isExpanded ? CinematicColors.accent : Colors.white10, shape: BoxShape.circle, boxShadow: isExpanded ? [const BoxShadow(color: CinematicColors.accent, blurRadius: 10)] : []),
          child: Icon(isExpanded ? Icons.close : Icons.menu, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _GlowingMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;
  const _GlowingMenuItem({required this.icon, required this.label, required this.isSelected, required this.isExpanded, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: isExpanded ? 12 : 0), 
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: isSelected ? CinematicColors.accent.withOpacity(0.15) : Colors.transparent, border: isSelected ? Border.all(color: CinematicColors.accent.withOpacity(0.5), width: 1) : null),
          child: Row(
            mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.white54, size: 24),
              if (isExpanded) ...[
                const SizedBox(width: 14),
                Expanded(child: Text(label, style: GoogleFonts.montserrat(color: isSelected ? Colors.white : Colors.white70, fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UserFooter extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onTap;
  const _UserFooter({required this.isExpanded, required this.onTap});
  
  @override
  Widget build(BuildContext context) {
    if (!isExpanded) {
      return Center(
        child: Container(
          width: 40, height: 40,
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white24),
          child: const CircleAvatar(radius: 18, backgroundColor: Color(0xFF333333), child: Icon(Icons.person, size: 20, color: Colors.white)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white24),
            child: const CircleAvatar(radius: 14, backgroundColor: Color(0xFF333333), child: Icon(Icons.person, size: 16, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          // --- CORRECCIÓN FINAL DE OVERFLOW ---
          // Usamos Expanded para que la columna ocupe el resto del ancho y nada más.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, 
              children: [
                Flexible( 
                  child: Text(
                    "Mi Usuario", 
                    style: GoogleFonts.roboto(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), 
                    overflow: TextOverflow.ellipsis, // Si no cabe, puntos suspensivos...
                    maxLines: 1,
                  ),
                ),
                const Text("Gratis", style: TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}