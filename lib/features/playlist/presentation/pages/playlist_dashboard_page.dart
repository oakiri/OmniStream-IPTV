import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/playlist_profile.dart';
import 'package:omnistream_iptv/injection_container.dart';
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
      barrierDismissible: false, // Obliga a usar botones para cerrar
      builder: (context) {
        return BlocProvider<PlaylistProfileBloc>.value(
          value: _profileBloc,
          child: const AddPlaylistDialog(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('Mis Listas', 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
      ),
      body: BlocProvider.value(
        value: _profileBloc,
        child: BlocBuilder<PlaylistProfileBloc, PlaylistProfileState>(
          builder: (context, state) {
            if (state is PlaylistProfileLoading) {
              return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
            } else if (state is PlaylistProfileLoaded) {
              return _buildGrid(state.profiles);
            } else if (state is PlaylistProfileError) {
              return Center(child: Text('Error: ${state.message}', style: const TextStyle(color: Colors.red)));
            }
            return const Center(child: Text('Sin datos', style: TextStyle(color: Colors.white)));
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: _showAddPlaylistDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildGrid(List<PlaylistProfile> profiles) {
    if (profiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.playlist_add, size: 80, color: Colors.grey[700]),
            const SizedBox(height: 20),
            const Text('No hay listas.\nAñade una pulsando +', 
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 18)
            ),
          ],
        ),
      );
    }
    
    // Usamos LayoutBuilder para adaptar el Grid si es tablet o móvil
    return LayoutBuilder(
      builder: (context, constraints) {
        // Si es muy ancho (tablet/TV), ponemos 3 columnas, si no 2
        int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20, 
            mainAxisSpacing: 20, 
            childAspectRatio: 0.8, // Tarjetas más altas para que quepa el botón
          ),
          itemCount: profiles.length,
          itemBuilder: (context, index) {
            final profile = profiles[index];
            return _buildProfileCard(profile);
          },
        );
      }
    );
  }

  Widget _buildProfileCard(PlaylistProfile profile) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // Gris oscuro elegante
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10), // Borde sutil
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Stack(
        children: [
          // Contenido Principal
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.tv, size: 40, color: Colors.blueAccent),
                ),
                const SizedBox(height: 15),
                Text(
                  profile.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                
                // BOTÓN ENTRAR EXPLÍCITO
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => context.pushNamed('playlist_home', extra: profile.url),
                    child: const Text('ENTRAR', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          
          // Botón Borrar (Esquina superior derecha)
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _showDeleteConfirm(profile),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(PlaylistProfile profile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('¿Eliminar lista?', style: TextStyle(color: Colors.white)),
        content: Text('Vas a eliminar "${profile.name}".', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey))
          ),
          TextButton(
            onPressed: () {
              _profileBloc.add(DeleteProfileEvent(profile.id));
              Navigator.pop(ctx);
            }, 
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }
}