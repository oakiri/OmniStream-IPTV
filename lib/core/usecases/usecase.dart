import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:omnistream_iptv/core/error/failure.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}
