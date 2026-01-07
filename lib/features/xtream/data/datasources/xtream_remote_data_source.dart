'''
import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/xtream_user_info_model.dart';

abstract class XtreamRemoteDataSource {
  Future<XtreamUserInfoModel> login(String serverUrl, String username, String password);
}

class XtreamRemoteDataSourceImpl implements XtreamRemoteDataSource {
  final Dio dio;

  XtreamRemoteDataSourceImpl({required this.dio});

  @override
  Future<XtreamUserInfoModel> login(String serverUrl, String username, String password) async {
    final response = await dio.get(
      '$serverUrl/player_api.php',
      queryParameters: {
        'username': username,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final userInfo = XtreamUserInfoModel.fromJson(response.data['user_info']);
      if (userInfo.auth == 1) {
        return userInfo;
      } else {
        throw ServerException();
      }
    } else {
      throw ServerException();
    }
  }
}
'''
