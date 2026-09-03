import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/returns/domain/entities/return_entity.dart';
import 'package:gear_track/feature/returns/domain/repository/return_repository.dart';

class ProcessReturn {
  final ReturnRepository repository;

  ProcessReturn(this.repository);

  Future<Either<Failure, ReturnEntity>> call(ReturnEntity returnEntity) async {
    if (returnEntity.items.isEmpty) {
      return Left(Failure('No items selected for return.'));
    }
    if (returnEntity.totalQuantity <= 0) {
      return Left(Failure('Return quantity must be greater than zero.'));
    }
    return await repository.processReturn(returnEntity);
  }
}
