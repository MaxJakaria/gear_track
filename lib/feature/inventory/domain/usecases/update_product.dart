import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/inventory/domain/entities/product.dart';
import 'package:gear_track/feature/inventory/domain/repository/inventory_repository.dart';

class UpdateProduct {
  final InventoryRepository repository;

  UpdateProduct(this.repository);

  Future<Either<Failure, void>> call(Product product) async {
    return await repository.updateProduct(product);
  }
}
