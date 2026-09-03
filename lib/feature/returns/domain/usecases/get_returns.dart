import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/returns/domain/entities/return_entity.dart';
import 'package:gear_track/feature/returns/domain/repository/return_repository.dart';

class GetReturns {
  final ReturnRepository repository;

  GetReturns(this.repository);

  Future<Either<Failure, List<ReturnEntity>>> call() async {
    return await repository.getReturns();
  }
}
