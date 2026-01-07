import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/epg_program.dart';

abstract class EpgRepository {
  Future<Either<Failure, List<EpgProgram>>> getEpgData(String url);
}
