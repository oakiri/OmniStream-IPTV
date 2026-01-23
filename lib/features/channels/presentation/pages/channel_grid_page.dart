import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_theme.dart';

import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_bloc.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_state.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_event.dart';
import 'package:omnistream_iptv/features/channels/presentation/widgets/channel_logo.dart';

class ChannelGridPage extends StatefulWidget {
  final String playlistUrl;

  const ChannelGridPage({super.key, required this.playlistUrl});

  @override
  State<ChannelGridPage> createState() => _ChannelGridPageState();
}

class _ChannelGridPageState extends State<ChannelGridPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fondo
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [Color(0xFF151515), Colors.black],
                ),
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder( // Responsive Real
              builder: (context, constraints) {
                bool isWide = constraints.maxWidth > 800; // Tablet/TV

                return BlocBuilder<ChannelBloc, ChannelState>(
                  builder: (context, state) {
                    if (state is ChannelLoading) {
                      return const Center(child: CircularProgressIndicator(color: CinematicColors.accent));
                    } else if (state is ChannelError) {
                      return Center(child: Text("Error: ${state.message}", style: GoogleFonts.montserrat(color: Colors.white)));
                    } else if (state is ChannelLoaded) {
                      // Layout
                      if (isWide) {
                         // TABLET / TV (Barra Izquierda)
                         return Row(
                           children: [
                             if (state.categories.isNotEmpty)
                               SizedBox(width: 250, child: _buildVerticalSidebar(state)),
                             Expanded(child: _buildMainContent(state, true)),
                           ],
                         );
                      } else {
                        // MOVIL (Barra Arriba)
                        return Column(
                          children: [
                            _buildMobileHeader(state),
                            if (state.categories.isNotEmpty)
                               SizedBox(height: 50, child: _buildHorizontalCategories(state)),
                            Expanded(child: _buildGrid(state.displayChannels, false)),
                          ],
                        );
                      }
                    }
                    return const SizedBox.shrink();
                  },
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildMainContent(ChannelLoaded state, bool isWide) {
    return Column(
      children: [
        _buildDesktopHeader(state.displayChannels.length),
        Expanded(child: _buildGrid(state.displayChannels, true)),
      ],
    );
  }

  Widget _buildVerticalSidebar(ChannelLoaded state) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text("CATEGORÍAS", style: GoogleFonts.audiowide(color: Colors.white38, fontSize: 12)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: state.categories.length,
              itemBuilder: (ctx, i) {
                final cat = state.categories[i];
                final isSel = cat == state.selectedCategory;
                return ListTile(
                  title: Text(cat, style: GoogleFonts.montserrat(color: isSel ? CinematicColors.accent : Colors.white70, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                  selected: isSel,
                  selectedTileColor: CinematicColors.accent.withOpacity(0.1),
                  onTap: () => context.read<ChannelBloc>().add(SelectCategory(cat)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCategories(ChannelLoaded state) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      itemCount: state.categories.length,
      itemBuilder: (ctx, i) {
        final cat = state.categories[i];
        final isSel = cat == state.selectedCategory;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(cat),
            labelStyle: GoogleFonts.montserrat(color: isSel ? Colors.black : Colors.white, fontSize: 12),
            selected: isSel,
            selectedColor: CinematicColors.accent,
            backgroundColor: Colors.white10,
            onSelected: (_) => context.read<ChannelBloc>().add(SelectCategory(cat)),
          ),
        );
      },
    );
  }

  Widget _buildDesktopHeader(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
          const SizedBox(width: 10),
          Text("CANALES", style: GoogleFonts.audiowide(color: Colors.white, fontSize: 20)),
          const Spacer(),
          SizedBox(
            width: 300,
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.montserrat(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Buscar...",
                hintStyle: GoogleFonts.montserrat(color: Colors.white24),
                prefixIcon: const Icon(Icons.search, color: Colors.white24),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onChanged: (v) => context.read<ChannelBloc>().add(SearchChannels(v)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(ChannelLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.montserrat(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Buscar canal...",
                  hintStyle: GoogleFonts.montserrat(color: Colors.white24),
                  prefixIcon: const Icon(Icons.search, color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => context.read<ChannelBloc>().add(SearchChannels(v)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Channel> channels, bool isWide) {
    return AnimationLimiter(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isWide ? 6 : 3, // Adaptable
          childAspectRatio: 0.85, 
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: channels.length,
        itemBuilder: (ctx, i) {
          return AnimationConfiguration.staggeredGrid(
            position: i,
            duration: const Duration(milliseconds: 300),
            columnCount: isWide ? 6 : 3,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _ChannelCard(
                  channel: channels[i],
                  onTap: () => context.pushNamed('player', extra: {"channel": channels[i], "channels": channels}),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChannelCard extends StatefulWidget {
  final Channel channel;
  final VoidCallback onTap;
  const _ChannelCard({required this.channel, required this.onTap});

  @override
  State<_ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<_ChannelCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: const Color(0xFFE0E0E0), // NEUTRO CLARO
            borderRadius: BorderRadius.circular(8),
            border: _isHovered ? Border.all(color: CinematicColors.accent, width: 2) : null,
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: ChannelLogo(url: widget.channel.logoUrl, width: 60, height: 60),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E), // PIE OSCURO
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                ),
                child: Text(
                  widget.channel.name,
                  style: GoogleFonts.montserrat(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}