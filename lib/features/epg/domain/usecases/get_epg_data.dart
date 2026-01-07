'''
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/models/epg_program.dart';
import '../repositories/epg_repository.dart';

class GetEpgData implements UseCase<List<EpgProgram>, Params> {
  final EpgRepository repository;

  GetEpgData(this.repository);

  @override
  Future<Either<Failure, List<EpgProgram>>> call(Params params) async {
    return await repository.getEpgData(params.url);
  }
}

class Params extends Equatable {
  final String url;

  const Params({required this.url});

  @override
  List<Object> get props => [url];
}
'''
