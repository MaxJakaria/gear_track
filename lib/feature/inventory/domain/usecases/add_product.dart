import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/inventory/domain/entities/product.dart';
import 'package:gear_track/feature/inventory/domain/repository/inventory_repository.dart';

class AddProduct {
  final InventoryRepository repository;

  AddProduct(this.repository);

  Future<Either<Failure, void>> call(Product product) async {
    return await repository.addProduct(product);
  }
}
