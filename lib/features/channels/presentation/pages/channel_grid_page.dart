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
  final String? initialChannelId;
  final String? initialChannelUrl;
  final bool autoPlayInitialChannel;

  const ChannelGridPage({
    super.key,
    required this.playlistUrl,
    this.initialChannelId,
    this.initialChannelUrl,
    this.autoPlayInitialChannel = false,
  });

  @override
  State<ChannelGridPage> createState() => _ChannelGridPageState();
}

class _ChannelGridPageState extends State<ChannelGridPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _autoOpened = false;

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
                  center: Alignment.topRight,
                  radius: 1.4,
                  colors: [Color(0xFF181818), Colors.black],
                ),
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isLargeScreen = constraints.maxWidth > 700;

                return BlocBuilder<ChannelBloc, ChannelState>(
                  builder: (context, state) {
                    if (state is ChannelLoading) {
                      return const Center(child: CircularProgressIndicator(color: CinematicColors.accent));
                    } else if (state is ChannelError) {
                      return Center(
                        child: Text(
                          'Error: ${state.message}',
                          style: GoogleFonts.montserrat(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      );
                    } else if (state is ChannelLoaded) {
                      _maybeAutoOpenPlayer(state);

                      if (isLargeScreen) {
                        // DISEÑO TV/TABLET (Barra lateral)
                        return Row(
                          children: [
                            if (state.categories.isNotEmpty)
                              SizedBox(width: 280, child: _buildSidebar(state)),
                            Expanded(child: _buildGridContent(state, true)),
                          ],
                        );
                      }

                      // DISEÑO MÓVIL
                      return Column(
                        children: [
                          _buildMobileHeader(state.displayChannels.length),
                          if (state.categories.isNotEmpty) _buildHorizontalCategories(state),
                          Expanded(child: _buildGridContent(state, false)),
                        ],
                      );
                    }

                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _maybeAutoOpenPlayer(ChannelLoaded state) {
    if (_autoOpened) return;
    if (!widget.autoPlayInitialChannel) return;

    final targetId = (widget.initialChannelId ?? '').trim();
    final targetUrl = (widget.initialChannelUrl ?? '').trim();

    if (targetId.isEmpty && targetUrl.isEmpty) return;

    // Buscamos en todos los canales para reanudar de forma consistente,
    // incluso si los IDs vienen vacíos o duplicados. Preferimos URL cuando exista.
    int idx = -1;
    if (targetId.isNotEmpty) {
      idx = state.allChannels.indexWhere((c) => c.id == targetId);
    }
    if (idx < 0 && targetUrl.isNotEmpty) {
      idx = state.allChannels.indexWhere((c) => c.url == targetUrl);
    }
    if (idx < 0) return;

    _autoOpened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final channel = state.allChannels[idx];
      context.pushNamed(
        'player',
        extra: {
          'channel': channel,
          'channels': state.allChannels,
          'playlistUrl': widget.playlistUrl,
        },
      );
    });
  }


  bool _isCategorySelected(ChannelLoaded state, String category) {
    if (category == 'All') return state.selectedCategories.isEmpty;
    return state.selectedCategories.contains(category);
  }

  // Header Móvil
  Widget _buildMobileHeader(int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.montserrat(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar canal…',
                  hintStyle: GoogleFonts.montserrat(color: Colors.white30, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.white30, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(bottom: 10),
                ),
                onChanged: (v) => context.read<ChannelBloc>().add(SearchChannels(v)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sidebar TV
  Widget _buildSidebar(ChannelLoaded state) {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'CATEGORÍAS',
              style: GoogleFonts.montserrat(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: state.categories.length,
              itemBuilder: (ctx, i) {
                final cat = state.categories[i];
                final isSel = _isCategorySelected(state, cat);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSel ? CinematicColors.accent.withOpacity(0.14) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSel ? CinematicColors.accent.withOpacity(0.35) : Colors.white.withOpacity(0.06),
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text(
                      cat,
                      style: GoogleFonts.montserrat(
                        color: isSel ? Colors.white : Colors.white70,
                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    trailing: Icon(
                      isSel ? Icons.check_circle : Icons.circle_outlined,
                      size: 18,
                      color: isSel ? CinematicColors.accent : Colors.white24,
                    ),
                    onTap: () => context.read<ChannelBloc>().add(SelectCategory(cat)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Categorías Horizontal (Móvil)
  Widget _buildHorizontalCategories(ChannelLoaded state) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: state.categories.length,
        itemBuilder: (ctx, i) {
          final cat = state.categories[i];
          final isSel = _isCategorySelected(state, cat);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat),
              labelStyle: GoogleFonts.montserrat(
                color: isSel ? Colors.black : Colors.white70,
                fontSize: 12,
                fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
              ),
              selected: isSel,
              selectedColor: CinematicColors.accent,
              backgroundColor: Colors.white10,
              checkmarkColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide.none,
              ),
              onSelected: (_) => context.read<ChannelBloc>().add(SelectCategory(cat)),
            ),
          );
        },
      ),
    );
  }

  // Grid Adaptativo
  Widget _buildGridContent(ChannelLoaded state, bool isWide) {
    if (state.displayChannels.isEmpty) {
      return Center(child: Text('Sin resultados', style: GoogleFonts.montserrat(color: Colors.white30)));
    }


    final targetId = (widget.initialChannelId ?? '').trim();
    final targetUrl = (widget.initialChannelUrl ?? '').trim();

    int highlightIndex = -1;
    if (targetUrl.isNotEmpty) {
      highlightIndex = state.displayChannels.indexWhere((c) => c.url == targetUrl);
    }
    if (highlightIndex < 0 && targetId.isNotEmpty) {
      highlightIndex = state.displayChannels.indexWhere((c) => c.id == targetId);
    }


    return Column(
      children: [
        if (isWide)
          Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, c) {
                final maxWidth = c.maxWidth;
                final searchMaxWidth = maxWidth < 420 ? maxWidth : 380.0;

                return Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 12,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'CANALES',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: searchMaxWidth),
                      child: SizedBox(
                        height: 44,
                        child: TextField(
                          controller: _searchController,
                          style: GoogleFonts.montserrat(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Buscar…',
                            hintStyle: GoogleFonts.montserrat(color: Colors.white30),
                            prefixIcon: const Icon(Icons.search, color: Colors.white30),
                            filled: true,
                            fillColor: Colors.white10,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          onChanged: (v) => context.read<ChannelBloc>().add(SearchChannels(v)),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        Expanded(
          child: AnimationLimiter(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 5 : 3,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: state.displayChannels.length,
              itemBuilder: (ctx, i) {
                final channel = state.displayChannels[i];
                final highlight = (highlightIndex >= 0) && (i == highlightIndex);

                return AnimationConfiguration.staggeredGrid(
                  position: i,
                  duration: const Duration(milliseconds: 300),
                  columnCount: isWide ? 5 : 3,
                  child: ScaleAnimation(
                    child: FadeInAnimation(
                      child: _ChannelCard(
                        channel: channel,
                        isHighlighted: highlight,
                        onTap: () => context.pushNamed(
                          'player',
                          extra: {
                            'channel': channel,
                            'channels': state.allChannels,
                            'playlistUrl': widget.playlistUrl,
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ChannelCard extends StatefulWidget {
  final Channel channel;
  final VoidCallback onTap;
  final bool isHighlighted;

  const _ChannelCard({
    required this.channel,
    required this.onTap,
    required this.isHighlighted,
  });

  @override
  State<_ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<_ChannelCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isHighlighted
        ? CinematicColors.accent
        : (_hover ? CinematicColors.accent.withOpacity(0.85) : Colors.white.withOpacity(0.05));

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: const Color(0xFF222222),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: widget.isHighlighted || _hover ? 2 : 1,
            ),
            boxShadow: (widget.isHighlighted || _hover)
                ? [BoxShadow(color: CinematicColors.accent.withOpacity(0.18), blurRadius: 16)]
                : [],
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: ChannelLogo(url: widget.channel.logoUrl, width: 60, height: 60),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      widget.channel.name,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
