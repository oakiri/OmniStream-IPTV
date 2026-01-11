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
      backgroundColor: Colors.black, // Fondo negro elegante
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('Mis Listas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
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
    
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, 
        crossAxisSpacing: 20, 
        mainAxisSpacing: 20, 
        childAspectRatio: 0.85, // Ajuste para que las tarjetas sean un poco más altas
      ),
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        return _buildProfileCard(profile);
      },
    );
  }

  Widget _buildProfileCard(PlaylistProfile profile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.blueAccent.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: Colors.white10),
      ),
      child: Stack(
        children: [
          // Área Clickable para entrar
          InkWell(
            onTap: () {
              // Navegación corregida: Ahora 'playlist_home' existe en main.dart
              context.pushNamed('playlist_home', extra: profile.url);
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Centrado Vertical
                crossAxisAlignment: CrossAxisAlignment.center, // Centrado Horizontal
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blueAccent.withOpacity(0.1),
                    ),
                    child: const Icon(Icons.tv, size: 40, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  const Text("ENTRAR", style: TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          
          // Botón de Borrar (Arriba a la derecha)
          Positioned(
            top: 5, 
            right: 5,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _showDeleteConfirm(profile),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.delete_outline, color: Colors.red[300], size: 20),
                ),
              ),
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
        title: const Text('¿Borrar lista?', style: TextStyle(color: Colors.white)),
        content: Text('Se eliminará "${profile.name}" de tus dispositivos.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              _profileBloc.add(DeleteProfileEvent(profile.id));
              Navigator.pop(ctx);
            }, 
            child: const Text('BORRAR', style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }
}