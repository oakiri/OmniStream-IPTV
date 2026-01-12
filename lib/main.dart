import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // <--- NUEVO IMPORT
import 'firebase_options.dart';
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
import 'package:omnistream_iptv/features/playlist/presentation/pages/playlist_home_page.dart';
import 'package:omnistream_iptv/features/speed_test/presentation/pages/speed_test_page.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';
import 'injection_container.dart' as di;
import 'package:omnistream_iptv/injection_container.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:omnistream_iptv/features/playlist/data/models/playlist_profile_model.dart';

// --- BACKGROUND HANDLER SEGURO (Fase 0 Fix) ---
// Este método debe estar FUERA de cualquier clase y marcado como entry-point.
// Se ejecuta en un proceso aislado (Isolate), por lo que NO tiene acceso a 'sl' ni a 'Get'.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Aseguramos que el motor de Flutter esté listo
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializamos Firebase solo para este proceso aislado
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // NOTA: No intentes usar 'sl<Service>' aquí porque GetIt no está inicializado en este isolate.
  // Si necesitas lógica compleja (como TimestampService), debes inicializarla aquí manualmente.
  debugPrint("📩 Mensaje en segundo plano recibido: ${message.messageId}");
}

final _router = GoRouter(
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
          create: (context) => sl<ChannelBloc>()
            ..add(LoadChannels(
              url: playlistUrl, 
              playlistId: playlistUrl,
            )), 
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // 1. Cargar Variables de Entorno
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("⚠️ .env no encontrado");
  }

  // 2. Inicializar Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // --- REGISTRO DEL HANDLER (Fase 0 Fix) ---
    // Esto sobrescribe cualquier handler antiguo corrupto
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await FirebaseAuth.instance.signInAnonymously(); 
    debugPrint("✅ Usuario Logueado ID: ${FirebaseAuth.instance.currentUser?.uid}");
  } catch (e) {
    debugPrint("❌ Error crítico en Firebase: $e");
  }

  // 3. Inicializar Almacenamiento Local e Inyección de Dependencias
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