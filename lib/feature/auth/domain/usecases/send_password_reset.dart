import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/auth/domain/repository/auth_repository.dart';

class SendPasswordReset {
  final AuthRepository repository;

  SendPasswordReset(this.repository);

  Future<Either<Failure, void>> call({required String email}) async {
    return await repository.sendPasswordResetEmail(email: email);
  }
}
