import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRemoteDataSource {
  Future<User?> signInAnonymously();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth; // Coincide con injection_container

  AuthRemoteDataSourceImpl({required this.firebaseAuth});

  @override
  Future<User?> signInAnonymously() async {
    final userCredential = await firebaseAuth.signInAnonymously();
    return userCredential.user;
  }
}