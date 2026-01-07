import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/epg_repository.dart';
import '../datasources/epg_remote_data_source.dart';
import '../models/epg_program.dart';

class EpgRepositoryImpl implements EpgRepository {
  final EpgRemoteDataSource remoteDataSource;

  EpgRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<EpgProgram>>> getEpgData(String url) async {
    try {
      final remoteEpgData = await remoteDataSource.getEpgData(url);
      return Right(remoteEpgData);
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}
