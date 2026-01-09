import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_bloc.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_state.dart';
// Importamos la entidad correcta (según tu código usas la de playlist o channels, ajusta si es necesario)
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart'; 
// IMPORTANTE: Importamos nuestro widget a prueba de fallos
import 'package:omnistream_iptv/features/channels/presentation/widgets/channel_logo.dart';

class ChannelGridPage extends StatefulWidget {
  final String playlistUrl; // Añadido para mantener consistencia si lo necesitas

  const ChannelGridPage({super.key, this.playlistUrl = ''});

  @override
  State<ChannelGridPage> createState() => _ChannelGridPageState();
}

class _ChannelGridPageState extends State<ChannelGridPage> {
  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canales TV'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar canal...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
      ),
      body: BlocBuilder<ChannelBloc, ChannelState>(
        builder: (context, state) {
          if (state is ChannelLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ChannelLoaded) {
            // Filtrado de canales
            final filteredChannels = state.channels.where((channel) {
              // Usamos 'groupTitle' como en tu corrección
              final matchesCategory = _selectedCategory == 'All' || 
                                    (channel.groupTitle ?? 'Otros') == _selectedCategory;
              final matchesSearch = channel.name.toLowerCase().contains(_searchQuery.toLowerCase());
              return matchesCategory && matchesSearch;
            }).toList();

            // Extraer categorías únicas
            final categories = ['All', ...state.channels
                .map((c) => c.groupTitle ?? 'Otros')
                .toSet()
                .toList()..sort()];

            return Column(
              children: [
                // Selector de Categorías (Horizontal)
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = category == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedCategory = category);
                          },
                        ),
                      );
                    },
                  ),
                ),
                
                // Grid de Canales
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, 
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: filteredChannels.length,
                    itemBuilder: (context, index) {
                      final channel = filteredChannels[index];
                      return _buildChannelCard(channel);
                    },
                  ),
                ),
              ],
            );
          } else if (state is ChannelError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const Center(child: Text('Sin canales disponibles'));
        },
      ),
    );
  }

  Widget _buildChannelCard(Channel channel) {
    return GestureDetector(
      onTap: () {
        context.push('/player', extra: {'channel': channel});
      },
      child: Card(
        elevation: 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                // AQUÍ ESTÁ EL CAMBIO CLAVE:
                // Usamos ChannelLogo en lugar de Image.network
                child: ChannelLogo(
                  url: channel.logoUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                channel.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}