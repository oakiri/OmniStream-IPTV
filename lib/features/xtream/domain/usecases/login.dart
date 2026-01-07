'''
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/models/xtream_user_info_model.dart';
import '../repositories/xtream_repository.dart';

class Login implements UseCase<XtreamUserInfoModel, Params> {
  final XtreamRepository repository;

  Login(this.repository);

  @override
  Future<Either<Failure, XtreamUserInfoModel>> call(Params params) async {
    return await repository.login(params.serverUrl, params.username, params.password);
  }
}

class Params extends Equatable {
  final String serverUrl;
  final String username;
  final String password;

  const Params({
    required this.serverUrl,
    required this.username,
    required this.password,
  });

  @override
  List<Object> get props => [serverUrl, username, password];
}
'''
