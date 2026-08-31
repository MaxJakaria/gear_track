import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/inventory/domain/repository/inventory_repository.dart';

class ClearAllProducts {
  final InventoryRepository repository;

  ClearAllProducts(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.clearAllProducts();
  }
}
