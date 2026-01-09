import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_bloc.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_event.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_state.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';
import 'package:omnistream_iptv/injection_container.dart';
// IMPORTANTE: Importamos el widget
import 'package:omnistream_iptv/features/channels/presentation/widgets/channel_logo.dart';

class ChannelListPage extends StatefulWidget {
  final String playlistUrl;

  const ChannelListPage({Key? key, required this.playlistUrl}) : super(key: key);

  @override
  State<ChannelListPage> createState() => _ChannelListPageState();
}

class _ChannelListPageState extends State<ChannelListPage> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => sl<ChannelBloc>()..add(LoadChannels(url: widget.playlistUrl, playlistId: widget.playlistUrl)),
        child: BlocBuilder<ChannelBloc, ChannelState>(
          builder: (context, state) {
            if (state is ChannelLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ChannelLoaded) {
              // Usamos groupTitle (ajusta a 'group' si tu entidad Channel antigua lo usa)
              final categories = ['All', ...state.channels.map((e) => e.groupTitle ?? 'Otros').toSet().toList()];
              
              final filteredChannels = _selectedCategory == 'All'
                  ? state.channels
                  : state.channels.where((c) => (c.groupTitle ?? 'Otros') == _selectedCategory).toList();

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    floating: true,
                    title: const Text('Canales'),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(50),
                      child: SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            final isSelected = cat == _selectedCategory;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(cat),
                                selected: isSelected,
                                onSelected: (bool selected) {
                                  setState(() {
                                    _selectedCategory = cat;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final channel = filteredChannels[index];
                        return ListTile(
                          leading: SizedBox(
                            width: 50,
                            height: 50,
                            // AQUÍ ESTÁ EL CAMBIO CLAVE:
                            child: ChannelLogo(
                              url: channel.logoUrl,
                              width: 50,
                              height: 50,
                            ),
                          ),
                          title: Text(
                            channel.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            channel.groupTitle ?? 'Sin categoría',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                          onTap: () {
                            context.push("/player", extra: {"channel": channel, "channels": filteredChannels});
                          },
                        );
                      },
                      childCount: filteredChannels.length,
                    ),
                  ),
                ],
              );
            } else if (state is ChannelError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}