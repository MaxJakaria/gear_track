import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, User>> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  });

  Future<Either<Failure, bool>> checkAuthStatus();

  Future<Either<Failure, void>> signOut();
}
