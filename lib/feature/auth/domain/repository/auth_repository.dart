import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, String>> sendSignInLink();
  Stream<bool> watchSessionApproval(String sessionId);
  Future<Either<Failure, void>> completeSessionLogin(String sessionId);
  Future<Either<Failure, bool>> checkAuthStatus();
  Future<Either<Failure, void>> signOut();
}
