import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/playlist/domain/entities/channel.dart';
import '../../features/playlist/presentation/pages/playlist_dashboard_page.dart';
import '../../features/playlist/presentation/pages/playlist_home_page.dart';
import '../../features/playlist/presentation/pages/player_page.dart';
import '../../features/playlist/presentation/pages/channel_list_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const PlaylistDashboardPage(),
      ),

      // Playlist Home (requiere playlistUrl)
      GoRoute(
        path: '/playlist',
        builder: (context, state) {
          final playlistUrl = state.uri.queryParameters['playlistUrl'];
          if (playlistUrl == null || playlistUrl.isEmpty) {
            // fallback: vuelve al dashboard
            return const PlaylistDashboardPage();
          }
          return PlaylistHomePage(playlistUrl: playlistUrl);
        },
      ),

      // Lista de canales (requiere playlistUrl)
      GoRoute(
        path: '/channels',
        builder: (context, state) {
          final playlistUrl = state.uri.queryParameters['playlistUrl'];
          if (playlistUrl == null || playlistUrl.isEmpty) {
            return const PlaylistDashboardPage();
          }
          return ChannelListPage(playlistUrl: playlistUrl);
        },
      ),

      // Player (requiere Channel por extra)
      GoRoute(
        path: '/player',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! Channel) {
            return const Scaffold(
              body: Center(
                child: Text('No channel provided to /player'),
              ),
            );
          }
          return PlayerPage(channel: extra);
        },
      ),
    ],
  );
}
