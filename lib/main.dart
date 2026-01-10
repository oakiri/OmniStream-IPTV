import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Imports Funcionalidad
import 'package:omnistream_iptv/features/playlist/presentation/bloc/playlist_profile_bloc.dart';
import 'package:omnistream_iptv/features/playlist/presentation/pages/playlist_dashboard_page.dart';
import 'package:omnistream_iptv/features/playlist/presentation/pages/playlist_home_page.dart'; 
import 'package:omnistream_iptv/core/theme/app_theme.dart';
import 'package:omnistream_iptv/features/channels/presentation/pages/channel_grid_page.dart';
import 'package:omnistream_iptv/features/channels/presentation/pages/video_player_page.dart';
import 'package:omnistream_iptv/features/channels/presentation/pages/quad_view_page.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_bloc.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_event.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart'; // CORREGIDO SEGÚN LOG

import 'injection_container.dart' as di;

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'dashboard',
      builder: (context, state) => const PlaylistDashboardPage(),
    ),
    GoRoute(
      path: '/playlist_home',
      name: 'playlist_home',
      builder: (context, state) {
        final playlistUrl = state.extra as String?;
        return PlaylistHomePage(playlistUrl: playlistUrl ?? '');
      },
    ),
    GoRoute(
      path: '/channels',
      name: 'channels',
      builder: (context, state) {
        final playlistUrl = state.extra as String?;
        return ChannelGridPage(playlistUrl: playlistUrl ?? '');
      },
    ),
    GoRoute(
      path: '/quad_view',
      name: 'quad_view',
      builder: (context, state) {
        // CORREGIDO: QuadView espera una lista de canales, no una URL
        return const QuadViewPage(channels: []); 
      },
    ),
    GoRoute(
      path: '/player',
      name: 'player',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>?;
        final dynamic channel = extras?['channel'];
        final dynamic channels = extras?['channels'];

        if (channel == null) {
          return const Scaffold(body: Center(child: Text('Error: Canal no válido')));
        }
        return VideoPlayerPage(channel: channel, channels: channels ?? []);
      },
    ),
  ],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("⚠️ .env no encontrado");
  }

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await FirebaseAuth.instance.signInAnonymously(); 
    debugPrint("✅ Usuario Logueado ID: ${FirebaseAuth.instance.currentUser?.uid}");
  } catch (e) {
    debugPrint("❌ Error crítico en Firebase: $e");
  }

  await Hive.initFlutter();
  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<PlaylistProfileBloc>()..add(LoadPlaylistProfiles())),
        BlocProvider(create: (_) => di.sl<ChannelBloc>()),
      ],
      child: MaterialApp.router(
        title: 'OmniStream IPTV',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: _router,
      ),
    );
  }
}