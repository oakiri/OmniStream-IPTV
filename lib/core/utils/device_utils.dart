import 'package:flutter/foundation.dart' show kIsWeb;

import 'dart:io';

class DeviceUtils {
  static bool get isMobile {
    if (kIsWeb) {
      return false;
    }
    return Platform.isAndroid || Platform.isIOS;
  }

  static bool get isTv {
    if (kIsWeb) {
      return false;
    }
    // A simple heuristic to detect TV devices.
    // This might need to be adjusted based on more specific device characteristics.
    return Platform.isAndroid &&
        (Platform.operatingSystemVersion.contains('Android TV') ||
            Platform.operatingSystemVersion.contains('Fire OS'));
  }
}
