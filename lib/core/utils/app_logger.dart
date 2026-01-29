import 'package:flutter/foundation.dart';

/// Logger muy simple para tener logs "bonitos" en consola.
///
/// Uso:
///   final log = const AppLogger('playlist.dashboard');
///   log.ui('tap add');
///
/// Nota: usamos debugPrint para evitar cortar líneas largas.
class AppLogger {
  final String scope;
  const AppLogger(this.scope);

  void ui(String message) => _out('UI', message);
  void nav(String message) => _out('NAV', message);
  void data(String message) => _out('DATA', message);
  void warn(String message) => _out('WARN', message);
  void error(String message) => _out('ERROR', message);

  void _out(String tag, String message) {
    // Solo en debug para no ensuciar logs de release.
    if (!kDebugMode) return;
    debugPrint('[$tag][$scope] $message');
  }
}
