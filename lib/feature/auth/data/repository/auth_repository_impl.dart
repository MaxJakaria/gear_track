import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/auth/data/sources/auth_remote_data_source.dart';
import 'package:gear_track/feature/auth/domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, String>> sendSignInLink() async {
    try {
      final sessionId = await remoteDataSource.sendSignInLink();
      return Right(sessionId);
    } on FirebaseAuthException catch (e) {
      return Left(Failure(e.message ?? 'Failed to send sign-in link.'));
    } catch (e) {
      return Left(Failure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  @override
  Stream<bool> watchSessionApproval(String sessionId) {
    return remoteDataSource.watchSessionApproval(sessionId);
  }

  @override
  Future<Either<Failure, void>> completeSessionLogin(String sessionId) async {
    try {
      await remoteDataSource.completeSessionLogin(sessionId);
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, bool>> checkAuthStatus() async {
    try {
      final isAuthenticated = await remoteDataSource.checkAuthStatus();
      return Right(isAuthenticated);
    } catch (e) {
      return Left(Failure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
