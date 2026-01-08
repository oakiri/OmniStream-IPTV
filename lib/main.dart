import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:go_router/go_router.dart';
import 'package:omnistream_iptv/features/playlist/presentation/bloc/playlist_profile_bloc.dart';
import 'package:omnistream_iptv/features/playlist/presentation/pages/playlist_dashboard_page.dart';
import 'package:omnistream_iptv/core/theme/app_theme.dart';
import 'package:omnistream_iptv/features/channels/presentation/pages/channel_grid_page.dart';
import 'package:omnistream_iptv/features/channels/presentation/pages/video_player_page.dart';
import 'package:omnistream_iptv/features/channels/presentation/pages/quad_view_page.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_bloc.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_event.dart';
import 'package:omnistream_iptv/features/navigation/presentation/pages/home_page.dart';
import 'package:omnistream_iptv/features/speed_test/presentation/pages/speed_test_page.dart';
import 'package:omnistream_iptv/features/channels/domain/entities/channel.dart';
import 'injection_container.dart' as di;
import 'package:omnistream_iptv/injection_container.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final _router = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const PlaylistDashboardPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) {
        final playlistUrl = state.extra as String? ?? 'http://example.com/playlist.m3u';
        return HomePage(playlistUrl: playlistUrl);
      },
    ),
    GoRoute(
      path: '/speed_test',
      builder: (context, state) => const SpeedTestPage(),
    ),
    GoRoute(
      path: '/quad_view',
      builder: (context, state) {
        final channels = state.extra as List<Channel>?;
        return QuadViewPage(channels: channels ?? []);
      },
    ),
    GoRoute(
      path: '/channels',
      name: 'channels',
      builder: (context, state) {
        final playlistUrl = state.extra as String?;
        if (playlistUrl == null) {
          return const Scaffold(
            body: Center(
              child: Text('Error: URL de la lista no proporcionada.'),
            ),
          );
        }
        return BlocProvider(
          create: (context) => sl<ChannelBloc>()..add(LoadChannels(playlistUrl)),
          child: ChannelGridPage(playlistUrl: playlistUrl),
        );
      },
    ),
    GoRoute(
      path: '/player',
      name: 'player',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final channel = extra?["channel"] as Channel?;
        final channels = extra?["channels"] as List<Channel>?;
        if (channel == null) {
          return const Scaffold(
            body: Center(
              child: Text('Error: Channel no proporcionado.'),
            ),
          );
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
    print("⚠️ No se pudo cargar el archivo .env: $e");
  }

  try {
    await Firebase.initializeApp();
    
  } catch (e) {
    
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
        BlocProvider(
          create: (_) => di.sl<PlaylistProfileBloc>()..add(LoadPlaylistProfiles()),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: _router,
        title: 'OmniStream IPTV',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
      ),
    );
  }
}
