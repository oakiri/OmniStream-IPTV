import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:omnistream_iptv/core/error/failure.dart';
import 'package:omnistream_iptv/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:omnistream_iptv/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, User?>> signInAnonymously() async {
    try {
      final user = await remoteDataSource.signInAnonymously();
      return Right(user);
    } on FirebaseAuthException catch (e) {
      // CORRECCI�N: Constructor posicional, sin 'message:'
      return Left(ServerFailure(e.message ?? 'Unknown Firebase error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}