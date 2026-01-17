import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:omnistream_iptv/core/theme/cinematic_theme.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_background.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_glass_card.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_platform_badges.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_bloc.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_event.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_state.dart';
import 'package:omnistream_iptv/injection_container.dart';
// IMPORTANTE: Importamos el widget
import 'package:omnistream_iptv/features/channels/presentation/widgets/channel_logo.dart';

class ChannelListPage extends StatefulWidget {
  final String playlistUrl;

  const ChannelListPage({Key? key, required this.playlistUrl})
      : super(key: key);

  @override
  State<ChannelListPage> createState() => _ChannelListPageState();
}

class _ChannelListPageState extends State<ChannelListPage> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CinematicBackground(
        child: SafeArea(
          child: BlocProvider(
            create: (context) => sl<ChannelBloc>()
              ..add(LoadChannels(
                  url: widget.playlistUrl, playlistId: widget.playlistUrl)),
            child: BlocBuilder<ChannelBloc, ChannelState>(
              builder: (context, state) {
                if (state is ChannelLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ChannelLoaded) {
                  // Usamos groupTitle (ajusta a 'group' si tu entidad Channel antigua lo usa)
                  final categories = [
                    'All',
                    ...state.channels
                        .map((e) => e.groupTitle ?? 'Otros')
                        .toSet()
                        .toList()
                  ];

                  final filteredChannels = _selectedCategory == 'All'
                      ? state.channels
                      : state.channels
                          .where((c) =>
                              (c.groupTitle ?? 'Otros') == _selectedCategory)
                          .toList();

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: CinematicGlassCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.tv,
                                    color: CinematicColors.accentSoft),
                                const SizedBox(width: 10),
                                Text(
                                  'Canales',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: CinematicColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final cat = categories[index];
                              final isSelected = cat == _selectedCategory;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = cat;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? CinematicColors.accent
                                              .withOpacity(0.22)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isSelected
                                            ? CinematicColors.accentSoft
                                            : CinematicColors.stroke,
                                      ),
                                    ),
                                    child: Text(
                                      cat,
                                      style: TextStyle(
                                        color: isSelected
                                            ? CinematicColors.textPrimary
                                            : CinematicColors.textMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final channel = filteredChannels[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () {
                                    context.push("/player", extra: {
                                      "channel": channel,
                                      "channels": filteredChannels
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: CinematicGlassCard(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 50,
                                          height: 50,
                                          child: ChannelLogo(
                                            url: channel.logoUrl,
                                            width: 50,
                                            height: 50,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                channel.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      CinematicColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                channel.groupTitle ??
                                                    'Sin categoría',
                                                style: const TextStyle(
                                                    color:
                                                        CinematicColors.textMuted,
                                                    fontSize: 12),
                                              ),
                                              const SizedBox(height: 8),
                                              CinematicPlatformBadges.placeholder(),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.play_circle_fill,
                                            color: CinematicColors.accentSoft),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: filteredChannels.length,
                          ),
                        ),
                      ),
                    ],
                  );
                } else if (state is ChannelError) {
                  return Center(
                      child: Text('Error: ${state.message}',
                          style:
                              const TextStyle(color: CinematicColors.textMuted)));
                }
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
  }
}
