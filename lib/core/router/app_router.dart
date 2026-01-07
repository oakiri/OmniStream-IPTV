import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';
import 'package:omnistream_iptv/features/playlist/presentation/pages/home_page.dart';
import 'package:omnistream_iptv/features/playlist/presentation/pages/player_page.dart';
import 'package:omnistream_iptv/features/epg/presentation/pages/epg_page.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/player',
      name: 'player',
      builder: (context, state) {
        final channel = state.extra as Channel;
        return PlayerPage(channel: channel);
      },
    ),
    GoRoute(
      path: '/epg',
      name: 'epg',
      builder: (context, state) {
        final epgUrl = state.extra as String;
        return EpgPage(epgUrl: epgUrl);
      },
    ),
  ],
);
