import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:omnistream_iptv/features/channels/domain/entities/channel.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_bloc.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_event.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_state.dart';

class ChannelGridPage extends StatefulWidget {
  final String playlistUrl;

  const ChannelGridPage({Key? key, required this.playlistUrl}) : super(key: key);

  @override
  State<ChannelGridPage> createState() => _ChannelGridPageState();
}

class _ChannelGridPageState extends State<ChannelGridPage> {
  late ChannelBloc _channelBloc;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    // El BLoC será inyectado desde el widget padre
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _channelBloc,
      child: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryFilter(),
          Expanded(
            child: BlocBuilder<ChannelBloc, ChannelState>(
              builder: (context, state) {
                if (state is ChannelLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ChannelLoaded) {
                  final filteredChannels = state.channels.where((channel) {
                    final matchesCategory = _selectedCategory == 'All' || channel.group == _selectedCategory;
                    final matchesSearch = channel.name.toLowerCase().contains(_searchQuery.toLowerCase());
                    return matchesCategory && matchesSearch;
                  }).toList();

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: filteredChannels.length,
                    itemBuilder: (context, index) {
                      final channel = filteredChannels[index];
                      return Card(
                        child: Column(
                          children: [
                            Expanded(
                              child: CachedNetworkImage(
                                imageUrl: channel.logoUrl ?? '',
                                fit: BoxFit.contain,
                                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) => const Icon(Icons.tv, size: 48),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                channel.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                } else if (state is ChannelError) {
                  return Center(child: Text(state.message));
                } else {
                  return const Center(child: Text('No hay canales para mostrar'));
                }
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
        onChanged: (query) {
          setState(() {
            _searchQuery = query;
          });
        },
        decoration: const InputDecoration(
          hintText: 'Buscar canales...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
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
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(category!),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
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
