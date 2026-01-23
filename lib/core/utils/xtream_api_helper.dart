import 'dart:convert';
import 'package:http/http.dart' as http;

class XtreamApiHelper {
  static Future<DateTime?> checkExpiration(String m3uUrl) async {
    try {
      final uri = Uri.parse(m3uUrl);
      
      // 1. Detectar si es Xtream
      if (!uri.path.contains('get.php')) return null;

      // 2. Construir URL de la API
      final apiUrl = uri.replace(path: uri.path.replaceAll('get.php', 'player_api.php'));

      // 3. Petición con Headers (User-Agent) para evitar bloqueo
      final response = await http.get(
        apiUrl,
        headers: {
          'User-Agent': 'IPTV Smarters Pro', // Nos disfrazamos de una app conocida
          'Accept': '*/*',
        }
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data is Map && data.containsKey('user_info')) {
          final userInfo = data['user_info'];
          // A veces viene como "exp_date" o "active_cons"
          final expDate = userInfo['exp_date']; 

          if (expDate != null) {
            // Caso null/"null" string
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
      print("Error obteniendo caducidad: $e");
    }
    return null;
  }
}