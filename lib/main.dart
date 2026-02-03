import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';

import 'injection_container.dart' as di;

import 'package:omnistream_iptv/core/router/app_router.dart';
import 'package:omnistream_iptv/core/theme/app_theme.dart';

// Hive models (adapters)
import 'package:omnistream_iptv/features/playlist/data/models/channel_model.dart';
import 'package:omnistream_iptv/features/playlist/data/models/category_model.dart';
import 'package:omnistream_iptv/features/playlist/data/models/epg_program_model.dart';
import 'package:omnistream_iptv/features/playlist/data/models/favorite_channel_model.dart';
import 'package:omnistream_iptv/features/playlist/data/models/playlist_profile_model.dart';

// Global BLoCs
import 'package:omnistream_iptv/features/playlist/presentation/bloc/playlist_profile_bloc.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // Intl: evita crashes (LocaleDataException) al formatear fechas/horas con locale explícito (p.ej. 'es').
  final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
  final localeName = deviceLocale.toString(); // ej: es_ES
  Intl.defaultLocale = localeName;
  try {
    await initializeDateFormatting(localeName);
  } catch (_) {
    // Fallback: languageCode (ej: 'es')
    try {
      await initializeDateFormatting(deviceLocale.languageCode);
    } catch (_) {}
  }
  // Asegura símbolos en español cuando alguna pantalla fuerza 'es'.
  try {
    await initializeDateFormatting('es');
  } catch (_) {}

  // Soporte híbrido: móvil (portrait/landscape) + TV (landscape)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Firebase
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    // Firebase Auth / Analytics / Crashlytics / RemoteConfig se integrarán en fases posteriores.
    // Mantener esta inicialización mínima evita ruido en logs durante el desarrollo.
  } catch (e) {
    debugPrint('Firebase init error (ignored if already initialized): $e');
  }

  // Hive (adapters MUST be registered before any openBox)
  await Hive.initFlutter();

  // NOTE: Keep typeIds unique. FavoriteChannelModel uses typeId 4.
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ChannelModelAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(PlaylistProfileModelAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(EPGProgramModelAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(CategoryModelAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(FavoriteChannelModelAdapter());

  // DI
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
        title: 'VIVID IPTV',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
