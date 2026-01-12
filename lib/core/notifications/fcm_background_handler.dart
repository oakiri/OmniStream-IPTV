import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:omnistream_iptv/core/di/app_di.dart';
// Si tienes firebase_options.dart generado por FlutterFire, úsalo:
// import 'package:omnistream_iptv/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // ✅ Recomendado si usas firebase_options.dart:
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // ✅ Si no lo tienes, normalmente Android tira de google-services.json:
    await Firebase.initializeApp();

    // ✅ IMPORTANTÍSIMO: DI también en este isolate
    AppDI.register();

    // Aquí ya puedes usar código que haga Get.find<TimestampService>() sin petar.

  } catch (e, st) {
    // Evita que un error mate el proceso
    // ignore: avoid_print
    print('FCM background handler error: $e\n$st');
  }
}
