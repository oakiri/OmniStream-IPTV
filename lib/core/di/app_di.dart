import 'package:omnistream_iptv/core/database/hive_service.dart';

class AppDI {
  static Future<void> init() async {
    // HiveService.init() es método de instancia, no estático
    await HiveService().init();
  }
}
