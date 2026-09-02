import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/auth/domain/repository/auth_repository.dart';

class LoginWithEmailPassword {
  final AuthRepository repository;

  LoginWithEmailPassword(this.repository);

  Future<Either<Failure, User>> call({
    required String email,
    required String password,
  }) async {
    return await repository.signInWithEmailPassword(
      email: email,
      password: password,
    );
  }
}
