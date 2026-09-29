import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/inventory/domain/entities/grouped_product.dart';
import 'package:gear_track/feature/inventory/domain/repository/inventory_repository.dart';

class UpdateGroupedProductDetails {
  final InventoryRepository repository;

  UpdateGroupedProductDetails(this.repository);

  Future<Either<Failure, void>> call({
    required GroupedProduct groupedProduct,
    required String newItemName,
    required String newModel,
  }) async {
    return await repository.updateGroupedProductDetails(
      groupedProduct: groupedProduct,
      newItemName: newItemName,
      newModel: newModel,
    );
  }
}
