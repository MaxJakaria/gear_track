import 'package:gear_track/feature/auth/domain/repository/auth_repository.dart';

class WatchSessionApproval {
  final AuthRepository repository;

  WatchSessionApproval(this.repository);

  Stream<bool> call(String sessionId) {
    return repository.watchSessionApproval(sessionId);
  }
}
