import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';

import 'package:omnistream_iptv/features/playlist/domain/entities/playlist_profile.dart';
import 'package:omnistream_iptv/injection_container.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_theme.dart';
import '../widgets/add_playlist_dialog.dart';
import 'package:omnistream_iptv/features/playlist/presentation/bloc/playlist_profile_bloc.dart';

class PlaylistDashboardPage extends StatefulWidget {
  const PlaylistDashboardPage({super.key});

  @override
  State<PlaylistDashboardPage> createState() => _PlaylistDashboardPageState();
}

class _PlaylistDashboardPageState extends State<PlaylistDashboardPage> {
  late PlaylistProfileBloc _profileBloc;

  @override
  void initState() {
    super.initState();
    _profileBloc = sl<PlaylistProfileBloc>();
    _profileBloc.add(LoadPlaylistProfiles());
  }

  void _showAddPlaylistDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // Más desenfoque WOW
          child: BlocProvider<PlaylistProfileBloc>.value(
            value: _profileBloc,
            child: const AddPlaylistDialog(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Padding lateral que respeta el Notch y bordes curvos
    final double sidePadding = MediaQuery.of(context).size.width > 600 ? 60 : 20;

    return Scaffold(
      backgroundColor: Colors.transparent, // Fondo manejado por MainShell o Global
      body: Stack(
        children: [
          // Decoración de fondo sutil
          Positioned(
            top: -150,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  CinematicColors.accent.withOpacity(0.15),
                  Colors.transparent
                ]),
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(sidePadding, 40, sidePadding, 20),
                  sliver: SliverToBoxAdapter(child: _buildHeader()),
                ),

                BlocBuilder<PlaylistProfileBloc, PlaylistProfileState>(
                  bloc: _profileBloc,
                  builder: (context, state) {
                    if (state is PlaylistProfileLoading) {
                      return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator(color: CinematicColors.accent)),
                      );
                    } else if (state is PlaylistProfileError) {
                      return SliverFillRemaining(
                        child: Center(child: Text(state.message, style: GoogleFonts.montserrat(color: Colors.redAccent))),
                      );
                    } else if (state is PlaylistProfilesLoaded) {
                      if (state.profiles.isEmpty) {
                        return SliverFillRemaining(child: _buildEmptyState());
                      }
                      return _buildCinematicGrid(state.profiles, sidePadding);
                    }
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  },
                ),
                
                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            ),
          ),
        ],
      ),
      
      floatingActionButton: _buildCinematicFAB(),
    );
  }

  Widget _buildCinematicFAB() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: CinematicColors.accent.withOpacity(0.6), blurRadius: 20, spreadRadius: 0),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _showAddPlaylistDialog,
        backgroundColor: CinematicColors.accent,
        elevation: 0,
        child: const Icon(Icons.add_link_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildHeader() {
    final String date = DateFormat('EEEE, d MMMM').format(DateTime.now()); 

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          date.toUpperCase(),
          style: GoogleFonts.montserrat(
            color: Colors.white54,
            fontSize: 11,
            letterSpacing: 3.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Mis Listas",
          style: GoogleFonts.audiowide(
            color: Colors.white,
            fontSize: 28,
            shadows: [
              Shadow(color: CinematicColors.accent.withOpacity(0.5), blurRadius: 15),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.playlist_add_check_circle, size: 80, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 20),
          Text(
            'Tu espacio está vacío',
            style: GoogleFonts.audiowide(color: Colors.white60, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Añade una lista M3U o Xtream para comenzar',
            style: GoogleFonts.montserrat(color: Colors.white30, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCinematicGrid(List<PlaylistProfile> profiles, double sidePadding) {
    return AnimationLimiter(
      child: SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: sidePadding),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400, // Ancho máximo de tarjeta (Responsive)
            childAspectRatio: 2.2,   // Tarjetas apaisadas compactas (Estilo WOW)
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return AnimationConfiguration.staggeredGrid(
                position: index,
                duration: const Duration(milliseconds: 400),
                columnCount: 2,
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: _PlaylistCard(
                      profile: profiles[index],
                      onTap: () => context.pushNamed('channels', extra: profiles[index].url),
                      onDelete: () => _showDeleteConfirm(profiles[index]),
                    ),
                  ),
                ),
              );
            },
            childCount: profiles.length,
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(PlaylistProfile profile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Eliminar lista', style: GoogleFonts.audiowide(color: Colors.white, fontSize: 18)),
        content: Text('¿Seguro que quieres borrar "${profile.name}"?', 
          style: GoogleFonts.montserrat(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: Text('CANCELAR', style: GoogleFonts.montserrat(color: Colors.white38))
          ),
          TextButton(
            onPressed: () {
              _profileBloc.add(DeleteProfileEvent(profile.id));
              Navigator.pop(ctx);
            }, 
            child: Text('BORRAR', style: GoogleFonts.montserrat(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _PlaylistCard extends StatefulWidget {
  final PlaylistProfile profile;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PlaylistCard({required this.profile, required this.onTap, required this.onDelete});

  @override
  State<_PlaylistCard> createState() => _PlaylistCardState();
}

class _PlaylistCardState extends State<_PlaylistCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Diseño Compacto y Elegante
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A), // Fondo oscuro sólido
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered ? CinematicColors.accent : Colors.white.withOpacity(0.05),
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: _isHovered
                ? [BoxShadow(color: CinematicColors.accent.withOpacity(0.2), blurRadius: 15)]
                : [const BoxShadow(color: Colors.black45, blurRadius: 5, offset: Offset(0, 4))],
          ),
          child: Stack(
            children: [
              // Contenido
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Icono Grande Izquierda
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.dvr_rounded, color: CinematicColors.accent.withOpacity(0.8), size: 24),
                    ),
                    const SizedBox(width: 16),
                    
                    // Textos
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.profile.name,
                            style: GoogleFonts.montserrat(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.profile.url,
                            style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Expiración
                          if (widget.profile.expirationDate != null)
                             Padding(
                               padding: const EdgeInsets.only(top: 6),
                               child: _buildExpiration(widget.profile.expirationDate!),
                             ),
                        ],
                      ),
                    ),

                    // Botón Borrar
                    IconButton(
                      icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.3)),
                      onPressed: widget.onDelete,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpiration(DateTime expDate) {
    final days = expDate.difference(DateTime.now()).inDays;
    Color color = days > 7 ? Colors.green : (days > 0 ? Colors.orange : Colors.red);
    String text = days > 0 ? "$days días restantes" : "Caducada";
    
    return Row(
      children: [
        Icon(Icons.timer_outlined, color: color, size: 10),
        const SizedBox(width: 4),
        Text(text, style: GoogleFonts.montserrat(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }
}