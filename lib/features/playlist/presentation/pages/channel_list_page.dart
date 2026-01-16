import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/playlist_bloc.dart';
import '../bloc/playlist_event.dart';
import '../bloc/playlist_state.dart';

class ChannelListPage extends StatefulWidget {
  final String playlistUrl;

  const ChannelListPage({super.key, required this.playlistUrl});

  @override
  State<ChannelListPage> createState() => _ChannelListPageState();
}

class _ChannelListPageState extends State<ChannelListPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<PlaylistBloc>().add(LoadPlaylist(url: widget.playlistUrl));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canales'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar canal o grupo…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    context.read<PlaylistBloc>().add(const ClearFilter());
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                context.read<PlaylistBloc>().add(FilterChannels(value));
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<PlaylistBloc, PlaylistState>(
              builder: (context, state) {
                if (state is PlaylistLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is PlaylistError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(state.message),
                    ),
                  );
                }

                if (state is PlaylistLoaded) {
                  final items = state.filteredChannels;
                  if (items.isEmpty) {
                    return const Center(child: Text('No hay resultados.'));
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final ch = items[index];
                      return ListTile(
                        title: Text(ch.name ?? 'Canal'),
                        subtitle: Text(ch.group ?? ''),
                        onTap: () {
                          // Aquí navegarías al player con el channel.
                          // Ejemplo:
                          // context.push('/player', extra: ch);
                        },
                      );
                    },
                  );
                }

                if (state is PlaylistFiltering) {
                  return const Center(child: CircularProgressIndicator());
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
