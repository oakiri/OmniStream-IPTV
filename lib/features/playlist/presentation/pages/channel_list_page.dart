import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omnistream_iptv/core/theme/cinematic_theme.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_background.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_glass_card.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_platform_badges.dart';

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
      backgroundColor: Colors.transparent,
      body: CinematicBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: CinematicGlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.live_tv,
                          color: CinematicColors.accentSoft),
                      const SizedBox(width: 10),
                      Text(
                        'Canales',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: CinematicColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: CinematicGlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Buscar canal o grupo…',
                      hintStyle: const TextStyle(
                          color: CinematicColors.textMuted),
                      prefixIcon: const Icon(Icons.search,
                          color: CinematicColors.textMuted),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear,
                            color: CinematicColors.textMuted),
                        onPressed: () {
                          _searchCtrl.clear();
                          context.read<PlaylistBloc>().add(const ClearFilter());
                        },
                      ),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(color: CinematicColors.textPrimary),
                    onChanged: (value) {
                      context.read<PlaylistBloc>().add(FilterChannels(value));
                    },
                  ),
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
                          child: Text(
                            state.message,
                            style:
                                const TextStyle(color: CinematicColors.textMuted),
                          ),
                        ),
                      );
                    }

                    if (state is PlaylistLoaded) {
                      final items = state.filteredChannels;
                      if (items.isEmpty) {
                        return const Center(
                          child: Text(
                            'No hay resultados.',
                            style: TextStyle(color: CinematicColors.textMuted),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final ch = items[index];
                          return CinematicGlassCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: CinematicColors.backgroundElevated
                                        .withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: CinematicColors.stroke),
                                  ),
                                  child: const Icon(Icons.tv,
                                      color: CinematicColors.textPrimary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ch.name ?? 'Canal',
                                        style: const TextStyle(
                                          color: CinematicColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        ch.group ?? 'Sin grupo',
                                        style: const TextStyle(
                                            color: CinematicColors.textMuted),
                                      ),
                                      const SizedBox(height: 8),
                                      CinematicPlatformBadges.placeholder(),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.play_arrow,
                                      color: CinematicColors.accentSoft),
                                ),
                              ],
                            ),
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
        ),
      ),
    );
  }
}
