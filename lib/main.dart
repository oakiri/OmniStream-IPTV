
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:go_router/go_router.dart'; // NECESARIO PARA LA NAVEGACIÓN
import 'package:omnistream_iptv/features/playlist/presentation/bloc/playlist_profile_bloc.dart';
import 'package:omnistream_iptv/features/playlist/presentation/pages/playlist_dashboard_page.dart';
import 'package:omnistream_iptv/core/theme/app_theme.dart';
import 'package:omnistream_iptv/features/channels/presentation/pages/channel_list_page.dart';
import 'package:omnistream_iptv/features/channels/presentation/pages/video_player_page.dart';
import 'package:omnistream_iptv/features/channels/domain/entities/channel.dart';
import 'injection_container.dart' as di;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// --- CONFIGURACIÓN DE RUTAS ---
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    // Ruta Principal: Dashboard de Listas
    GoRoute(
      path: '/',
      builder: (context, state) => const PlaylistDashboardPage(),
    ),
    // Ruta de Canales (La que fallaba al hacer clic)
    GoRoute(
      path: '/channels',
      name: 'channels',
      builder: (context, state) {
        // Recuperamos la URL que pasamos desde el Dashboard
        final playlistUrl = state.extra as String?;
        
        if (playlistUrl == null) {
          return const Scaffold(
            body: Center(
              child: Text('Error: URL de la lista no proporcionada.'),
            ),
          );
        }
        return ChannelListPage(playlistUrl: playlistUrl); // <-- CORRECTO
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
  
  // 1. Inicializar MediaKit
  MediaKit.ensureInitialized();

  // 2. Cargar variables de entorno
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("⚠️ No se pudo cargar el archivo .env: $e");
  }

  // 3. Inicializar Firebase (Modo Seguro)
  try {
    await Firebase.initializeApp();
    print("✅ Firebase inicializado correctamente.");
  } catch (e) {
    print("⚠️ Falló Firebase (Falta google-services.json). Modo OFFLINE activado.");
  }

  // 4. Inicializar Hive
  await Hive.initFlutter();

  // 5. Inicializar Inyección de Dependencias
  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // El Bloc de Perfiles que carga la lista inicial
        BlocProvider(
          create: (_) => di.sl<PlaylistProfileBloc>()..add(LoadPlaylistProfiles()),
        ),
        // Aquí añadirás el PlaylistBloc (canales) cuando conectes la pantalla real
        // BlocProvider(create: (_) => di.sl<PlaylistBloc>()),
      ],
      // CAMBIO CLAVE: Usamos .router en lugar de MaterialApp normal
      child: MaterialApp.router(
        routerConfig: _router, // Conectamos el sistema de rutas
        title: 'OmniStream IPTV',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
      ),
    );
  }
}
