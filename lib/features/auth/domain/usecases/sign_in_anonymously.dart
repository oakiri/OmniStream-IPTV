import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:omnistream_iptv/core/errors/failures.dart';
import 'package:omnistream_iptv/core/usecases/usecase.dart';
import 'package:omnistream_iptv/features/auth/domain/repositories/auth_repository.dart';

class SignInAnonymously implements UseCase<User?, NoParams> {
  final AuthRepository repository;

  SignInAnonymously(this.repository);

  @override
  Future<Either<Failure, User?>> call(NoParams params) async {
    return await repository.signInAnonymously();
  }
}
