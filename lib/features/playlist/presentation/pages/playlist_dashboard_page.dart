import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PlaylistDashboardPage extends StatefulWidget {
  const PlaylistDashboardPage({super.key});

  @override
  State<PlaylistDashboardPage> createState() => _PlaylistDashboardPageState();
}

class _PlaylistDashboardPageState extends State<PlaylistDashboardPage> {
  // ⚠️ Temporal: lista mock para que el dashboard funcione aunque todavía
  // estés arreglando Hive/Repo/Bloc. Luego lo conectamos al Bloc.
  final List<_PlaylistItem> _items = const [
    _PlaylistItem(
      id: 'demo-1',
      name: 'Demo Playlist',
      url: 'https://example.com/playlist.m3u',
      type: 'm3u',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F14),
        elevation: 0,
        title: const Text('Playlists'),
        actions: [
          IconButton(
            tooltip: 'Añadir',
            icon: const Icon(Icons.add),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _items.isEmpty
            ? _EmptyState(onAdd: _showAddDialog)
            : ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _PlaylistCard(
                    item: item,
                    onOpen: () {
                      // ✅ Navega al listado de canales pasando playlistUrl
                      context.goNamed(
                        'playlist_home',
                        extra: item.url,
                      );
                    },
                    onMore: () => _showMoreSheet(item),
                  );
                },
              ),
      ),
    );
  }

  void _showAddDialog() {
    // Por ahora: diálogo simple (sin repo/bloc).
    // Cuando arreglemos DI/Bloc, aquí conectamos tu AddPlaylistDialog real.
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final nameCtrl = TextEditingController();
        final urlCtrl = TextEditingController();
        final typeCtrl = TextEditingController(text: 'm3u');

        return AlertDialog(
          title: const Text('Añadir playlist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(labelText: 'URL'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: typeCtrl,
                decoration:
                    const InputDecoration(labelText: 'Tipo (m3u/xtream)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                // Aquí luego dispararemos Bloc/AddPlaylistProfile usecase.
                Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _showMoreSheet(_PlaylistItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF121826),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const Icon(Icons.play_arrow, color: Colors.white),
                  title: const Text('Abrir',
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text(item.url,
                      style: const TextStyle(color: Colors.white54)),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.goNamed('playlist_home', extra: item.url);
                  },
                ),
                const Divider(color: Colors.white12),
                ListTile(
                  leading:
                      const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Eliminar',
                      style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    // Aquí luego conectamos DeletePlaylistProfile
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlaylistItem {
  final String id;
  final String name;
  final String url;
  final String? type;

  const _PlaylistItem({
    required this.id,
    required this.name,
    required this.url,
    this.type,
  });
}

class _PlaylistCard extends StatelessWidget {
  final _PlaylistItem item;
  final VoidCallback onOpen;
  final VoidCallback onMore;

  const _PlaylistCard({
    required this.item,
    required this.onOpen,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF121826),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.playlist_play, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (item.type != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.type!,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            IconButton(
              onPressed: onMore,
              icon: const Icon(Icons.more_vert, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(18),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: const Color(0xFF121826),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.playlist_add, size: 44, color: Colors.white),
            const SizedBox(height: 10),
            const Text(
              'Aún no tienes playlists',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Añade una URL M3U o Xtream para empezar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Añadir playlist'),
            ),
          ],
        ),
      ),
    );
  }
}
