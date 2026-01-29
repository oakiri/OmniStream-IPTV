import 'dart:convert';
import 'package:http/http.dart' as http;

class XtreamApiHelper {
  /// Verifica la caducidad. Devuelve null si no es Xtream o hay error.
  static Future<DateTime?> checkExpiration(String m3uUrl) async {
    try {
      // 1. Sanitización de URL (Evita el bug de doble barra //)
      String cleanUrl = m3uUrl;
      // Si la URL es válida parseala
      final uri = Uri.tryParse(cleanUrl);
      if (uri == null || !uri.path.contains('get.php')) return null;

      // 2. Construir la URL de la API (player_api.php)
      // Reemplazamos get.php por player_api.php manteniendo los query params
      final apiUrl = uri.replace(path: uri.path.replaceAll('get.php', 'player_api.php'));

      // 3. Petición "Disfrazada" (User-Agent)
      final response = await http.get(
        apiUrl,
        headers: {
          'User-Agent': 'IPTV Smarters Pro', // Nos hacemos pasar por una app estándar
          'Accept': '*/*',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data is Map && data.containsKey('user_info')) {
          final userInfo = data['user_info'];
          // 'exp_date' puede venir como int (timestamp) o string null
          final expDate = userInfo['exp_date'];

          if (expDate != null) {
            // Caso String "null"
            if (expDate.toString() == "null") return null;

            // Caso Timestamp numérico
            if (expDate is int) {
              return DateTime.fromMillisecondsSinceEpoch(expDate * 1000);
            }
            
            // Caso String numérico
            final expTimestamp = int.tryParse(expDate.toString());
            if (expTimestamp != null) {
              return DateTime.fromMillisecondsSinceEpoch(expTimestamp * 1000);
            }
          }
        }
      }
    } catch (e) {
      // Log silencioso para no ensuciar la consola en producción
      print("XtreamApiHelper: No se pudo obtener expiración: $e");
    }
    return null;
  }
}