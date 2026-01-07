import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:omnistream_iptv/core/usecases/usecase.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/playlist_profile.dart';
import 'package:omnistream_iptv/features/playlist/presentation/bloc/playlist_profile_bloc.dart';
import 'package:omnistream_iptv/features/playlist/presentation/bloc/playlist_profile_event.dart';
import 'package:omnistream_iptv/features/playlist/presentation/bloc/playlist_profile_state.dart';
import 'package:omnistream_iptv/injection_container.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_focus_watcher/flutter_focus_watcher.dart';

class PlaylistDashboardPage extends StatefulWidget {
  const PlaylistDashboardPage({Key? key}) : super(key: key);

  @override
  State<PlaylistDashboardPage> createState() => _PlaylistDashboardPageState();
}

class _PlaylistDashboardPageState extends State<PlaylistDashboardPage> {
  late PlaylistProfileBloc _profileBloc;

  @override
  void initState() {
    super.initState();
    _profileBloc = sl<PlaylistProfileBloc>();
    _profileBloc.add(GetProfilesEvent());
  }

  void _addTestProfile() {
    final newProfile = PlaylistProfile(
      id: const Uuid().v4(),
      name: 'Test List ${DateTime.now().second}',
      url: 'http://test.com/test.m3u',
      lastUpdated: DateTime.now(),
      isFavorite: false,
    );
    _profileBloc.add(AddProfileEvent(newProfile));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My IPTV Playlists',
          style: GoogleFonts.roboto(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
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
        onPressed: _addTestProfile, // Will be replaced by a dialog to add a real list
        child: const Icon(Icons.add),
      ),
    );
  }

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
              style: GoogleFonts.roboto(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first list.',
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return FocusTraversalGroup(
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: profiles.length,
        itemBuilder: (context, index) {
          final profile = profiles[index];
          return FocusWatcher(
            builder: (context, isFocused) {
              return Card(
                elevation: isFocused ? 8 : 4,
                margin: const EdgeInsets.only(bottom: 16),
                color: isFocused ? Colors.deepPurple.shade100 : null,
                child: ListTile(
                  leading: const Icon(Icons.live_tv, color: Colors.deepPurple),
                  title: Text(
                    profile.name,
                    style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Last updated: ${profile.lastUpdated.toLocal().toString().split(' ')[0]}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _profileBloc.add(DeleteProfileEvent(profile.id)),
                  ),
                  onTap: () {
                    context.pushNamed('channels', extra: profile.url);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
