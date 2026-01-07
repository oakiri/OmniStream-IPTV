'''
import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/xtream_repository.dart';
import '../datasources/xtream_remote_data_source.dart';
import '../models/xtream_user_info_model.dart';

class XtreamRepositoryImpl implements XtreamRepository {
  final XtreamRemoteDataSource remoteDataSource;

  XtreamRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, XtreamUserInfoModel>> login(
    String serverUrl,
    String username,
    String password,
  ) async {
    try {
      final userInfo = await remoteDataSource.login(serverUrl, username, password);
      return Right(userInfo);
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}
'''
