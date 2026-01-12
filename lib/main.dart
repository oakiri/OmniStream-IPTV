import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';

import 'injection_container.dart' as di;

import 'package:omnistream_iptv/core/theme/app_theme.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_bloc.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_event.dart';
import 'package:omnistream_iptv/features/channels/presentation/pages/channel_grid_page.dart';
import 'package:omnistream_iptv/features/channels/presentation/pages/quad_view_page.dart';
import 'package:omnistream_iptv/features/channels/presentation/pages/video_player_page.dart';
import 'package:omnistream_iptv/features/playlist/data/models/playlist_profile_model.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';
import 'package:omnistream_iptv/features/playlist/presentation/bloc/playlist_profile_bloc.dart';
import 'package:omnistream_iptv/features/playlist/presentation/pages/playlist_dashboard_page.dart';
import 'package:omnistream_iptv/features/playlist/presentation/pages/playlist_home_page.dart';
import 'package:omnistream_iptv/features/speed_test/presentation/pages/speed_test_page.dart';

/// ✅ IMPORTANTE:
/// - Mantenemos ESTE nombre porque si el sistema tiene un callback antiguo guardado,
///   suele seguir apuntando a la función top-level que existía.
/// - Esta versión NO usa GetX ni DI.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint("📩 FCM background OK (neutralizado): ${message.messageId}");
  } catch (e, st) {
    debugPrint("❌ Error FCM background handler: $e");
    debugPrint("$st");
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const PlaylistDashboardPage(),
    ),
    GoRoute(
      path: '/home',
      name: 'playlist_home',
      builder: (context, state) {
        final playlistUrl = state.extra as String? ?? '';
        return PlaylistHomePage(playlistUrl: playlistUrl);
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
            body: Center(child: Text('Error: URL de la lista no proporcionada.')),
          );
        }

        return BlocProvider(
          create: (_) => di.sl<ChannelBloc>()
            ..add(
              LoadChannels(
                url: playlistUrl,
                playlistId: playlistUrl,
              ),
            ),
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
            body: Center(child: Text('Error: Channel no proporcionado.')),
          );
        }

        return VideoPlayerPage(channel: channel, channels: channels ?? []);
      },
    ),
  ],
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // 1) Variables de entorno
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    debugPrint("⚠️ .env no encontrado");
  }

  // 2) Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAuth.instance.signInAnonymously();
    debugPrint("✅ Usuario Logueado ID: ${FirebaseAuth.instance.currentUser?.uid}");
  } catch (e) {
    debugPrint("❌ Error crítico en Firebase: $e");
  }

  // 3) Hive + DI
  await Hive.initFlutter();
  Hive.registerAdapter(PlaylistProfileModelAdapter());
  await di.init();

  // ✅ CLAVE: registra el background handler LO ÚLTIMO (sobrescribe cualquiera anterior)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              di.sl<PlaylistProfileBloc>()..add(LoadPlaylistProfiles()),
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
