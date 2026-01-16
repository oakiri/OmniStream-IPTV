import 'package:http/http.dart' as http;
import 'package:omnistream_iptv/core/errors/exceptions.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint

abstract class ChannelRemoteDataSource {
  Future<String> getM3UContent(String url);
}

class ChannelRemoteDataSourceImpl implements ChannelRemoteDataSource {
  final http.Client client;

  ChannelRemoteDataSourceImpl({required this.client});

  @override
  Future<String> getM3UContent(String url) async {
    final uri = Uri.parse(url);

    // INTENTO 1: Simular ser IPTV Smarters Pro
    try {
      debugPrint('📡 Intentando conectar (Modo Smarters): $url');
      final headers = {
        'User-Agent': 'IPTV Smarters Pro',
        'Accept': '*/*',
        'Connection': 'keep-alive',
      };

      final response = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10)); // Timeout de seguridad

      debugPrint('📡 Respuesta 1 - Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) return response.body;
      }
    } catch (e) {
      debugPrint('⚠️ Falló Intento 1: $e');
      // No lanzamos error todavía, dejamos que pase al intento 2
    }

    // INTENTO 2: Simular ser un Navegador Web (Chrome)
    // A veces los servidores bloquean 'IPTV Smarters' pero aceptan navegadores
    try {
      debugPrint('🔄 Intentando conectar (Modo Navegador): $url');
      final headersBrowser = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      };

      final response = await client
          .get(uri, headers: headersBrowser)
          .timeout(const Duration(seconds: 10));

      debugPrint('📡 Respuesta 2 - Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        return response.body;
      }
    } catch (e) {
      debugPrint('⚠️ Falló Intento 2: $e');
    }

    // INTENTO 3: Sin headers (Crudo) - Último recurso
    try {
      debugPrint('🔄 Intentando conectar (Sin Headers)...');
      final response =
          await client.get(uri).timeout(const Duration(seconds: 10));

      debugPrint('📡 Respuesta 3 - Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        return response.body;
      }
    } catch (e) {
      debugPrint('❌ Falló Intento 3: $e');
    }

    // Si llegamos aquí, nada funcionó
    debugPrint('🛑 Error Fatal: No se pudo cargar la lista de ninguna forma.');
    throw ServerException();
  }
}
