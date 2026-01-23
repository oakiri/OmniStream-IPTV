import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:go_router/go_router.dart';

// --- INYECCIÓN ---
import 'injection_container.dart' as di;
import 'package:omnistream_iptv/injection_container.dart';

// --- CORE ---
import 'package:omnistream_iptv/core/theme/app_theme.dart';
import 'package:omnistream_iptv/features/playlist/data/models/playlist_profile_model.dart';

// --- BLOCS ---
import 'package:omnistream_iptv/features/playlist/presentation/bloc/playlist_profile_bloc.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_bloc.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_event.dart';

// --- PANTALLAS ---
import 'package:omnistream_iptv/features/navigation/presentation/pages/main_shell_page.dart';
import 'package:omnistream_iptv/features/playlist/presentation/pages/playlist_dashboard_page.dart';
import 'package:omnistream_iptv/features/channels/presentation/pages/channel_grid_page.dart';
// CORRECCIÓN DE RUTA (Según tu indicación):
import 'package:omnistream_iptv/features/channels/presentation/pages/video_player_page.dart';

// --- ENTITIES ---
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart'; 

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/playlist', // Arrancamos en el dashboard
  routes: [
    // 1. SHELL ROUTE (Contenedor Principal con Pestañas)
    // Esto soluciona el error "required named parameter 'navigationShell'"
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShellPage(navigationShell: navigationShell);
      },
      branches: [
        // RAMA 0: Playlist Dashboard
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/playlist',
              builder: (context, state) => const PlaylistDashboardPage(),
            ),
          ],
        ),
        // RAMA 1: Ajustes (Placeholder necesario para que el Shell funcione si tiene 2 tabs)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const Scaffold(
                backgroundColor: Colors.black,
                body: Center(child: Text("Ajustes", style: TextStyle(color: Colors.white))),
              ),
            ),
          ],
        ),
      ],
    ),
    
    // 2. RUTAS FUERA DEL SHELL (Pantalla completa, sin menú abajo/lateral)
    
    // Ruta Canales
    GoRoute(
      path: '/channels',
      name: 'channels',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final playlistUrl = state.extra as String?;
        return BlocProvider(
          create: (context) => sl<ChannelBloc>()..add(LoadChannels(url: playlistUrl ?? '', playlistId: playlistUrl ?? '')), 
          child: ChannelGridPage(playlistUrl: playlistUrl ?? ''),
        );
      },
    ),

    // Ruta Player
    GoRoute(
      path: '/player',
      name: 'player',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>;
        final channel = extras['channel'] as Channel;
        final channels = extras['channels'] as List<Channel>?;
        return VideoPlayerPage(channel: channel, channels: channels);
      },
    ),
  ],
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // FILOSOFÍA WOW: Permitir rotación en móvil y landscape en TV
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FirebaseAuth.instance.signInAnonymously(); 
  } catch (e) {
    debugPrint("Error Firebase: $e");
  }
  
  await Hive.initFlutter();
  Hive.registerAdapter(PlaylistProfileModelAdapter()); 
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