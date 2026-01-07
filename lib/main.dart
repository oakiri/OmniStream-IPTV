import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:omnistream_iptv/core/database/hive_service.dart';
import 'package:omnistream_iptv/injection_container.dart' as di;
import 'package:omnistream_iptv/core/router/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:omnistream_iptv/features/auth/domain/usecases/sign_in_anonymously.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize MediaKit FIRST - critical for video playback
  try {
    print('[MAIN] Initializing MediaKit...');
    MediaKit.ensureInitialized();
    print('✓ [MAIN] MediaKit initialized successfully');
  } catch (e) {
    print('❌ [MAIN] Error initializing MediaKit: $e');
  }
  
  // Load environment variables from .env file with maximum error handling
  try {
    print('[MAIN] Attempting to load .env file...');
    await dotenv.load(fileName: '.env');
    print('✓ [MAIN] .env file loaded successfully');
  } catch (e) {
    print('⚠ [MAIN] Warning: Failed to load .env file: $e');
    print('⚠ [MAIN] Error type: ${e.runtimeType}');
    print('⚠ [MAIN] Continuing with default values...');
    // Continue anyway - don't crash the app
  }
  
  try {
    // Initialize Hive for local storage
    print('[MAIN] Initializing Hive...');
    await HiveService().init();
    print('✓ [MAIN] Hive initialized');
  } catch (e) {
    print('❌ [MAIN] Error initializing Hive: $e');
  }
  
  try {
    // Initialize dependency injection
    print('[MAIN] Initializing dependency injection...');
    await di.init();

    // Initialize Firebase
    await Firebase.initializeApp();

    // Sign in anonymously
    final signInAnonymously = di.sl<SignInAnonymously>();
    await signInAnonymously(NoParams());
    print('✓ [MAIN] Dependency injection initialized');
  } catch (e) {
    print('❌ [MAIN] Error initializing DI: $e');
  }
  
  print('[MAIN] Starting app...');
  runApp(
    const ProviderScope(
      child: OmniStreamApp(),
    ),
  );
}

class OmniStreamApp extends StatelessWidget {
  const OmniStreamApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'OmniStream IPTV',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
