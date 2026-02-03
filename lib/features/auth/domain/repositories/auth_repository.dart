import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:omnistream_iptv/core/error/failure.dart';

abstract class AuthRepository {
  Future<Either<Failure, User?>> signInAnonymously();
}
