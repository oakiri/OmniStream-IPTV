import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:omnistream_iptv/core/database/hive_service.dart';
import 'package:omnistream_iptv/injection_container.dart' as di;
import 'package:omnistream_iptv/core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file with error handling
  try {
    await dotenv.load(fileName: '.env');
    print('✓ .env file loaded successfully');
  } catch (e) {
    print('⚠ Warning: Failed to load .env file: $e');
    print('⚠ Continuing with default values...');
  }
  
  // Initialize Hive for local storage
  await HiveService().init();
  
  // Initialize dependency injection
  await di.init();
  
  // Initialize MediaKit for video playback
  MediaKit.ensureInitialized();
  
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
