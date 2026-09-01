import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/auth/domain/repository/auth_repository.dart';

class SendSignInLink {
  final AuthRepository repository;

  SendSignInLink(this.repository);

  Future<Either<Failure, String>> call() async {
    return await repository.sendSignInLink();
  }
}
