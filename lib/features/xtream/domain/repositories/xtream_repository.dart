'''
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/xtream_user_info_model.dart';

abstract class XtreamRepository {
  Future<Either<Failure, XtreamUserInfoModel>> login(
    String serverUrl,
    String username,
    String password,
  );
}
'''
