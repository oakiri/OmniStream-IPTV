import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:omnistream_iptv/injection_container.dart';
import 'package:omnistream_iptv/features/navigation/presentation/pages/main_shell_page.dart';
import 'package:omnistream_iptv/features/navigation/presentation/pages/live_page.dart';
import 'package:omnistream_iptv/features/navigation/presentation/pages/vod_page.dart';
import 'package:omnistream_iptv/features/navigation/presentation/pages/settings_page.dart';

import 'package:omnistream_iptv/features/playlist/presentation/pages/playlist_dashboard_page.dart';
import 'package:omnistream_iptv/features/playlist/presentation/pages/add_playlist_flow_page.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/playlist_profile.dart';
import 'package:omnistream_iptv/features/channels/presentation/pages/channel_grid_page.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_bloc.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_event.dart';
import 'package:omnistream_iptv/features/channels/presentation/pages/video_player_page.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';

/// Root navigator key.
/// Routes using [parentNavigatorKey] with this key are shown above the Shell
/// (fullscreen) and hide bottom/side navigation.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/playlist',
    // Reduce ruido en logs: en release no queremos spam de router.
    debugLogDiagnostics: kDebugMode,
    routes: [
      /// FULLSCREEN FLOW - Add playlist wizard (no bottom/side navigation)
      GoRoute(
        path: '/playlist/add',
        name: 'addPlaylist',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          final edit = extra is PlaylistProfile ? extra : null;
          return AddPlaylistFlowPage(editingProfile: edit);
        },
      ),

      /// MAIN SHELL (persistent navigation)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellPage(navigationShell: navigationShell);
        },
        branches: [
          /// 0) Dashboard / Listas
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/playlist',
                name: 'playlist',
                builder: (context, state) => const PlaylistDashboardPage(),
                routes: [
                  /// Subroute: grid de canales (mantiene el Shell)
                  GoRoute(
                    path: 'channels',
                    name: 'channels',
                    builder: (context, state) {
                      final extra = state.extra;
                      String playlistUrl = '';
                      String? initialChannelId;
                      String? initialChannelUrl;
                      bool autoPlay = false;

                      if (extra is String) {
                        playlistUrl = extra;
                      } else if (extra is Map) {
                        playlistUrl = (extra['playlistUrl'] as String? ?? '');
                        initialChannelId = extra['initialChannelId'] as String?;
                        initialChannelUrl = extra['initialChannelUrl'] as String?;
                        autoPlay = extra['autoPlay'] as bool? ?? false;
                      }

                      playlistUrl = playlistUrl.trim();
                      return BlocProvider(
                        create: (_) => sl<ChannelBloc>()
                          ..add(
                            LoadChannels(
                              url: playlistUrl,
                              // TODO: cuando el Dashboard pase un ID real de playlist,
                              // cambia esto por profile.id.
                              playlistId: playlistUrl,
                            ),
                          ),
                        child: ChannelGridPage(
                          playlistUrl: playlistUrl,
                          initialChannelId: initialChannelId,
                          initialChannelUrl: initialChannelUrl,
                          autoPlayInitialChannel: autoPlay,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          /// 1) Live / EPG (fase 3)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/live',
                name: 'live',
                builder: (context, state) => const LivePage(),
              ),
            ],
          ),

          /// 2) VOD (fase futura)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/vod',
                name: 'vod',
                builder: (context, state) => const VodPage(),
              ),
            ],
          ),

          /// 3) Ajustes
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),

      /// FULLSCREEN ROUTES (above shell)
      GoRoute(
        path: '/player',
        name: 'player',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>?;
          if (extras == null || extras['channel'] == null) {
            // Fallback minimal (no placeholder page file). We keep it lightweight.
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Text('Error: sin datos de reproducción', style: TextStyle(color: Colors.white70)),
              ),
            );
          }
          return VideoPlayerPage(
            channel: extras['channel'] as Channel,
            channels: extras['channels'] as List<Channel>?,
            playlistUrl: extras['playlistUrl'] as String?,
          );
        },
      ),
    ],
  );
}
