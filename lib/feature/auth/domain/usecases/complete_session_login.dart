import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/auth/domain/repository/auth_repository.dart';

class CompleteSessionLogin {
  final AuthRepository repository;

  CompleteSessionLogin(this.repository);

  Future<Either<Failure, void>> call(String sessionId) async {
    return await repository.completeSessionLogin(sessionId);
  }
}
