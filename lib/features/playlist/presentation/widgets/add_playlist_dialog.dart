import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/playlist_profile.dart';
import 'package:omnistream_iptv/features/playlist/presentation/bloc/playlist_profile_bloc.dart';
import 'package:omnistream_iptv/features/playlist/presentation/bloc/playlist_profile_event.dart';
import 'package:uuid/uuid.dart';

class AddPlaylistDialog extends StatefulWidget {
  const AddPlaylistDialog({super.key});

  @override
  State<AddPlaylistDialog> createState() => _AddPlaylistDialogState();
}

class _AddPlaylistDialogState extends State<AddPlaylistDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _xtreamUrlController = TextEditingController();
  final TextEditingController _xtreamUsernameController = TextEditingController();
  final TextEditingController _xtreamPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _urlController.dispose();
    _xtreamUrlController.dispose();
    _xtreamUsernameController.dispose();
    _xtreamPasswordController.dispose();
    super.dispose();
  }

  void _addPlaylist() {
    final bloc = BlocProvider.of<PlaylistProfileBloc>(context);
    final currentTab = _tabController.index;
    String url = '';
    String name = _nameController.text.trim();

    if (name.isEmpty) {
      // Simple validation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for the playlist.')),
      );
      return;
    }

    if (currentTab == 0) {
      // M3U URL
      url = _urlController.text.trim();
      if (!url.startsWith('http')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid M3U URL.')),
        );
        return;
      }
    } else {
      // Xtream Codes (Placeholder logic for now)
      final xtreamUrl = _xtreamUrlController.text.trim();
      final username = _xtreamUsernameController.text.trim();
      final password = _xtreamPasswordController.text.trim();

      if (xtreamUrl.isEmpty || username.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all Xtream Codes fields.')),
        );
        return;
      }
      // Construct a placeholder URL for Xtream for now. The real logic will be complex.
      url = 'xtream://$xtreamUrl/$username/$password';
    }

    final newProfile = PlaylistProfile(
      id: const Uuid().v4(),
      name: name,
      url: url,
      lastUpdated: DateTime.now(),
      isFavorite: false,
      userId: '', // Will be filled by the repository using FirebaseAuth.currentUser.uid
    );

    bloc.add(AddProfileEvent(newProfile));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add New IPTV Playlist', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Playlist Name (e.g., My Provider)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'M3U URL'),
                  Tab(text: 'Xtream Codes'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200, // Fixed height for TabBarView
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // M3U URL Tab
                    Column(
                      children: [
                        TextField(
                          controller: _urlController,
                          decoration: const InputDecoration(
                            labelText: 'M3U URL (http://...)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Paste the full M3U URL provided by your service.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    // Xtream Codes Tab
                    Column(
                      children: [
                        TextField(
                          controller: _xtreamUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Server URL (e.g., http://provider.com:8080)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _xtreamUsernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _xtreamPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addPlaylist,
          child: const Text('Add Playlist'),
        ),
      ],
    );
  }
}
