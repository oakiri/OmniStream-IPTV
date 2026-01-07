import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/playlist_profile.dart';
import 'package:omnistream_iptv/injection_container.dart';
import '../widgets/add_playlist_dialog.dart';
// Eliminamos imports innecesarios de FocusWatcher
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
      appBar: AppBar(
        title: Text(
          'OmniStream IPTV',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocProvider(
        create: (_) => _profileBloc,
        child: BlocConsumer<PlaylistProfileBloc, PlaylistProfileState>(
          listener: (context, state) {
            if (state is PlaylistProfileError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${state.message}')),
              );
            }
          },
          builder: (context, state) {
            if (state is PlaylistProfileLoading || state is PlaylistProfileInitial) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is PlaylistProfileLoaded) {
              return _buildLoadedState(state.profiles);
            } else if (state is PlaylistProfileError) {
              return Center(child: Text('Failed to load profiles: ${state.message}'));
            }
            return const Center(child: Text('Unknown state'));
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPlaylistDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- AQUÍ ESTÁ LA CORRECCIÓN APLICADA ---
  Widget _buildLoadedState(List<PlaylistProfile> profiles) {
    if (profiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.playlist_add, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No playlists found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first list.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        // FIX: Usamos Card estándar sin FocusWatcher manual para evitar crash
        return Card(
          elevation: 4,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.pushNamed('channels', extra: profile.url),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.tv, size: 64, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    profile.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.pushNamed('channels', extra: profile.url),
                  child: const Text('ENTRAR'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}