import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omnistream_iptv/core/database/hive_service.dart';

void main() async {
  // Load environment variables from .env file
  await dotenv.load(fileName: '.env');
  
    await HiveService().init();

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
    return MaterialApp(
      title: 'OmniStream IPTV',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('OmniStream IPTV - Infrastructure Ready'),
        ),
      ),
    );
  }
}
