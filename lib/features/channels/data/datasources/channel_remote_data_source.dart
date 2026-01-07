import 'package:http/http.dart' as http;
import 'package:omnistream_iptv/core/errors/exceptions.dart';

abstract class ChannelRemoteDataSource {
  Future<String> getM3UContent(String url);
}

class ChannelRemoteDataSourceImpl implements ChannelRemoteDataSource {
  final http.Client client;

  ChannelRemoteDataSourceImpl({required this.client});

  @override
  Future<String> getM3UContent(String url) async {
    final response = await client.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw ServerException();
    }
  }
}
