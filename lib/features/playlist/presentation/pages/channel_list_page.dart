import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
// Eliminamos CachedNetworkImage porque ya no lo usamos directamente
// import 'package:cached_network_image/cached_network_image.dart'; 
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';
import 'package:omnistream_iptv/features/playlist/presentation/bloc/playlist_bloc.dart';
import 'package:omnistream_iptv/injection_container.dart';
import 'package:flutter_focus_watcher/flutter_focus_watcher.dart';
import '../widgets/toggle_favorite_button.dart';

// --- IMPORTANTE: Importamos el nuevo widget ChannelLogo ---
import 'package:omnistream_iptv/features/channels/presentation/widgets/channel_logo.dart'; 

class ChannelListPage extends StatefulWidget {
  final String playlistUrl;

  const ChannelListPage({Key? key, required this.playlistUrl}) : super(key: key);

  @override
  State<ChannelListPage> createState() => _ChannelListPageState();
}

class _ChannelListPageState extends State<ChannelListPage> with TickerProviderStateMixin {
  late PlaylistBloc _playlistBloc;
  late TextEditingController _searchController;
  late TabController _tabController;
  String _searchQuery = '';
  List<String> _categories = [];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _playlistBloc = sl<PlaylistBloc>();
    _searchController = TextEditingController();
    _tabController = TabController(length: 1, vsync: this);

    _playlistBloc.add(LoadPlaylist(widget.playlistUrl));

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _updateCategories(List<Channel> channels) {
    final categories = channels
        .map((c) => c.group)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    
    categories.insert(0, 'All');

    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = 'All';
    }

    setState(() {
      _categories = categories;
      _tabController = TabController(length: _categories.length, vsync: this);
      _tabController.addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() {
            _selectedCategory = _categories[_tabController.index];
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Channels',
          style: GoogleFonts.roboto(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search channels...',
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white70),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.deepPurple.shade700,
                    hintStyle: const TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: _categories.map((category) => Tab(text: category)).toList(),
              ),
            ],
          ),
        ),
      ),
      body: BlocProvider<PlaylistBloc>.value(
        value: _playlistBloc,
        child: BlocConsumer<PlaylistBloc, PlaylistState>(
          listener: (context, state) {
            if (state is PlaylistError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error loading playlist: ${state.message}')),
              );
            } else if (state is PlaylistLoaded) {
              _updateCategories(state.channels);
            }
          },
          builder: (context, state) {
            if (state is PlaylistLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is PlaylistLoaded) {
              return FutureBuilder<List<Channel>>(
                future: PlaylistBloc.filterChannelsInIsolate(state.channels, _searchQuery),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error filtering channels: ${snapshot.error}'));
                  }
                  // Aplicamos filtro de categoría localmente sobre el resultado de búsqueda
                  var filteredChannels = snapshot.data ?? [];
                  if (_selectedCategory != 'All') {
                    filteredChannels = filteredChannels
                        .where((c) => c.group == _selectedCategory)
                        .toList();
                  }

                  return _buildLoadedState(filteredChannels);
                },
              );
            } else if (state is PlaylistError) {
              return Center(child: Text('Failed to load playlist: ${state.message}'));
            }
            return const Center(child: Text('Enter a playlist URL to begin.'));
          },
        ),
      ),
    );
  }

  Widget _buildLoadedState(List<Channel> channels) {
    if (channels.isEmpty) {
      return const Center(child: Text('No channels found for this filter.'));
    }

    return FocusTraversalGroup(
      child: ListView.builder(
        itemCount: channels.length,
        itemBuilder: (context, index) {
          final channel = channels[index];
          return FocusWatcher(
            child: FocusableActionDetector(
              onShowFocusHighlight: (isFocused) {
                // No-op, FocusWatcher handles the focus state
              },
              child: Builder(
                builder: (context) {
                  final isFocused = Focus.of(context).hasPrimaryFocus;
                  return _buildChannelTile(context, channel, isFocused);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChannelTile(BuildContext context, Channel channel, bool isFocused) {
    return GestureDetector(
      onTap: () {
        context.push('/player', extra: channel);
      },
      child: Card(
        elevation: isFocused ? 8 : 4,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        color: isFocused ? Colors.deepPurple.shade100 : null,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // --- AQUÍ ESTÁ EL CAMBIO PRINCIPAL ---
              // Usamos ChannelLogo que maneja SVGs, errores y carga automáticamente
              ChannelLogo(
                url: channel.logoUrl,
                width: 40,
                height: 40,
              ),
              // -------------------------------------
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.name,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (channel.group != null && channel.group!.isNotEmpty)
                      Text(
                        channel.group!,
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              ToggleFavoriteButton(channel: channel),
              const Icon(Icons.play_arrow, color: Colors.deepPurple),
            ],
          ),
        ),
      ),
    );
  }
}