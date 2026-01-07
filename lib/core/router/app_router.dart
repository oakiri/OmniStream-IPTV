import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';

import 'package:omnistream_iptv/features/playlist/presentation/pages/playlist_dashboard_page.dart';
import 'package:omnistream_iptv/features/playlist/presentation/pages/player_page.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const PlaylistDashboardPage(),
    ),
    GoRoute(
      path: '/player',
      name: 'player',
      builder: (context, state) {
        final channel = state.extra as Channel;
        return PlayerPage(channel: channel);
      },
    ),
  ],
);
