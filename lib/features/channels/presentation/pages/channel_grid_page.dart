import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_bloc.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_event.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_state.dart';
import 'package:go_router/go_router.dart';

class ChannelGridPage extends StatefulWidget {
  final String playlistUrl;

  const ChannelGridPage({Key? key, required this.playlistUrl}) : super(key: key);

  @override
  State<ChannelGridPage> createState() => _ChannelGridPageState();
}

class _ChannelGridPageState extends State<ChannelGridPage> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      // Usar el playlistUrl como ID temporal o extraer ID real
      context.read<ChannelBloc>().add(LoadMoreChannels(widget.playlistUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Canales', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryFilter(),
          Expanded(
            child: BlocBuilder<ChannelBloc, ChannelState>(
              builder: (context, state) {
                if (state is ChannelLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.blueAccent),
                        SizedBox(height: 16),
                        Text('Iniciando sincronización...', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  );
                } else if (state is ChannelSyncing) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: state.progress,
                          color: Colors.blueAccent,
                          backgroundColor: Colors.white10,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sincronizando con la nube: ${state.current} / ${state.total}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(state.progress * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(color: Colors.blueAccent),
                        ),
                      ],
                    ),
                  );
                } else if (state is ChannelLoaded) {
                  final filteredChannels = state.channels.where((channel) {
                    final matchesCategory = _selectedCategory == 'All' || channel.group == _selectedCategory;
                    final matchesSearch = channel.name.toLowerCase().contains(_searchQuery.toLowerCase());
                    return matchesCategory && matchesSearch;
                  }).toList();

                  return GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: state.hasReachedMax ? filteredChannels.length : filteredChannels.length + 1,
                    itemBuilder: (context, index) {
                      if (index >= filteredChannels.length) {
                        return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                      }
                      
                      final channel = filteredChannels[index];
                      return InkWell(
                        onTap: () => context.pushNamed('player', extra: {"channel": channel, "channels": state.channels}),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: CachedNetworkImage(
                                    imageUrl: channel.logoUrl ?? '',
                                    placeholder: (context, url) => const Icon(Icons.tv, color: Colors.black45),
                                    errorWidget: (context, url, error) => const Icon(Icons.tv, size: 40, color: Colors.black),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Text(
                                  channel.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else if (state is ChannelError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 60),
                        const SizedBox(height: 16),
                        Text(state.message, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.read<ChannelBloc>().add(SyncChannelsWithFirestore(playlistId: widget.playlistUrl, url: widget.playlistUrl)),
                          child: const Text('Reintentar'),
                        )
                      ],
                    ),
                  );
                }
                return const Center(child: Text('Cargando...', style: TextStyle(color: Colors.white)));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        onChanged: (q) => setState(() => _searchQuery = q),
        decoration: InputDecoration(
          hintText: 'Buscar canales...',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          filled: true,
          fillColor: Colors.white10,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueAccent)),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return BlocBuilder<ChannelBloc, ChannelState>(
      builder: (context, state) {
        if (state is ChannelLoaded) {
          final categories = ['All', ...state.channels.map((c) => c.group).where((g) => g != null).toSet()];
          return SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(category!, style: TextStyle(color: _selectedCategory == category ? Colors.white : Colors.black)),
                    selected: _selectedCategory == category,
                    selectedColor: Colors.blueAccent,
                    onSelected: (val) => setState(() => _selectedCategory = category),
                  ),
                );
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
