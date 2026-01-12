import 'package:get/get.dart';
import 'package:omnistream_iptv/core/services/timestamp_service.dart';

class AppDI {
  static void register() {
    if (!Get.isRegistered<TimestampService>()) {
      Get.put<TimestampService>(TimestampService(), permanent: true);
    }

    // Si TimestampService depende de otros servicios, regístralos aquí también.
  }
}
