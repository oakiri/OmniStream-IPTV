import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:omnistream_iptv/core/theme/cinematic_theme.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_background.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_glass_card.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_platform_badges.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_side_menu.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_bloc.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_event.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_state.dart';

class ChannelGridPage extends StatelessWidget {
  final String playlistUrl;
  final bool showAppBar;
  final bool showBackground;

  const ChannelGridPage({
    super.key,
    required this.playlistUrl,
    this.showAppBar = true,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = Column(
      children: [
        if (showAppBar)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: CinematicGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    'Canales TV',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: CinematicColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh,
                        color: CinematicColors.textPrimary),
                    onPressed: () {
                      context.read<ChannelBloc>().add(
                          LoadChannels(url: playlistUrl, playlistId: playlistUrl));
                    },
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: CinematicGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              style: const TextStyle(color: CinematicColors.textPrimary),
              onChanged: (value) =>
                  context.read<ChannelBloc>().add(SearchChannels(value)),
              decoration: InputDecoration(
                hintText: 'Buscar canal...',
                hintStyle:
                    TextStyle(color: CinematicColors.textMuted.withOpacity(0.9)),
                prefixIcon: const Icon(Icons.search,
                    color: CinematicColors.textMuted),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 980;
              return BlocBuilder<ChannelBloc, ChannelState>(
                builder: (context, state) {
                  if (state is ChannelLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ChannelError) {
                    return Center(
                        child: Text(state.message,
                            style: const TextStyle(color: Colors.red)));
                  } else if (state is ChannelLoaded) {
                    final channels = state.displayChannels;
                    if (channels.isEmpty) {
                      return const Center(
                        child: Text(
                          "No hay canales en esta categoría",
                          style: TextStyle(color: CinematicColors.textMuted),
                        ),
                      );
                    }

                    final grid = GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWide ? 4 : 3,
                        childAspectRatio: isWide ? 1.05 : 0.85,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: channels.length,
                      itemBuilder: (context, index) {
                        final channel = channels[index];
                        return InkWell(
                          onTap: () {
                            context.pushNamed('player', extra: {
                              'channel': channel,
                              'channels': state.displayChannels
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: CinematicGlassCard(
                            padding: const EdgeInsets.all(12),
                            borderRadius: BorderRadius.circular(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: CachedNetworkImage(
                                      imageUrl: channel.logoUrl ?? "",
                                      fit: BoxFit.contain,
                                      placeholder: (context, url) =>
                                          const Center(
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2)),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.tv,
                                              size: 40,
                                              color: CinematicColors.textMuted),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  channel.name,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: CinematicColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                CinematicPlatformBadges.placeholder(),
                              ],
                            ),
                          ),
                        );
                      },
                    );

                    if (!isWide) {
                      return Column(
                        children: [
                          SizedBox(
                            height: 46,
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              scrollDirection: Axis.horizontal,
                              itemCount: state.categories.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final category = state.categories[index];
                                final isSelected =
                                    category == state.selectedCategory;
                                return InkWell(
                                  onTap: () {
                                    context
                                        .read<ChannelBloc>()
                                        .add(SelectCategory(category));
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
                                              : CinematicColors.stroke),
                                    ),
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        color: isSelected
                                            ? CinematicColors.textPrimary
                                            : CinematicColors.textMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(child: grid),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 220,
                          child: CinematicSideMenu(
                            title: 'Categorías',
                            items: state.categories,
                            selectedItem: state.selectedCategory,
                            onItemSelected: (category) {
                              context
                                  .read<ChannelBloc>()
                                  .add(SelectCategory(category));
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: grid),
                      ],
                    );
                  }
                  return const Center(
                    child: Text(
                      "Esperando canales...",
                      style: TextStyle(color: CinematicColors.textMuted),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );

    final scaffold = Scaffold(
      backgroundColor:
          showBackground ? Colors.transparent : theme.scaffoldBackgroundColor,
      body: SafeArea(child: body),
    );

    if (!showBackground) {
      return scaffold;
    }

    return CinematicBackground(child: scaffold);
  }
}
