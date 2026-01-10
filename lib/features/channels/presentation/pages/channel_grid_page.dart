import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_bloc.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_event.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_state.dart';

class ChannelGridPage extends StatelessWidget {
  final String playlistUrl;

  const ChannelGridPage({super.key, required this.playlistUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Canales TV'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ChannelBloc>().add(
                LoadChannels(url: playlistUrl, playlistId: playlistUrl)
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. BUSCADOR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            color: theme.scaffoldBackgroundColor,
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => context.read<ChannelBloc>().add(SearchChannels(value)),
              decoration: InputDecoration(
                hintText: 'Buscar canal...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
            ),
          ),

          // 2. BARRA DE CATEGORÍAS
          SizedBox(
            height: 50,
            child: BlocBuilder<ChannelBloc, ChannelState>(
              builder: (context, state) {
                if (state is ChannelLoaded) {
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: state.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final category = state.categories[index];
                      final isSelected = category == state.selectedCategory;
                      
                      return ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (_) {
                          context.read<ChannelBloc>().add(SelectCategory(category));
                        },
                        selectedColor: const Color(0xFF0D47A1), 
                        backgroundColor: theme.cardColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      );
                    },
                  );
                }
                return const SizedBox();
              },
            ),
          ),

          const Divider(height: 1, color: Colors.white24),

          // 3. GRID DE CANALES
          Expanded(
            child: BlocBuilder<ChannelBloc, ChannelState>(
              builder: (context, state) {
                if (state is ChannelLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ChannelError) {
                  return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
                } else if (state is ChannelLoaded) {
                  final channels = state.displayChannels;

                  if (channels.isEmpty) {
                    return const Center(child: Text("No hay canales en esta categoría"));
                  }

                  return GridView.builder(
                    // CAMBIO AQUÍ: Padding asimétrico.
                    // 12 arriba y lados, pero 100 abajo para salvar la barra de navegación.
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 100), 
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: channels.length,
                    itemBuilder: (context, index) {
                      final channel = channels[index];
                      return Card(
                        elevation: 4,
                        color: theme.cardColor,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: InkWell(
                          onTap: () {
                            context.pushNamed('player', extra: {
                              'channel': channel,
                              'channels': state.displayChannels
                            });
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ZONA DE IMAGEN
                              Expanded(
                                flex: 3,
                                child: Container(
                                  color: const Color(0xFFCFD8DC), // Gris Plata Perfecto
                                  padding: const EdgeInsets.all(8.0),
                                  child: CachedNetworkImage(
                                    imageUrl: channel.logoUrl ?? "",
                                    fit: BoxFit.contain,
                                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                    errorWidget: (context, url, error) => const Icon(Icons.tv, size: 40, color: Colors.grey),
                                  ),
                                ),
                              ),
                              
                              // ZONA DE TEXTO
                              Container(
                                height: 40,
                                color: const Color(0xFF0D47A1),
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                alignment: Alignment.center,
                                child: Text(
                                  channel.name,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
                return const Center(child: Text("Esperando canales..."));
              },
            ),
          ),
        ],
      ),
    );
  }
}