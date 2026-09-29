import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/inventory/domain/entities/grouped_product.dart';
import 'package:gear_track/feature/inventory/domain/entities/product.dart';

abstract class InventoryRepository {
  Future<Either<Failure, void>> addProduct(Product product);
  Future<Either<Failure, List<Product>>> getProducts();
  Future<Either<Failure, void>> updateProduct(Product product);
  Future<Either<Failure, void>> updateGroupedProductDetails({
    required GroupedProduct groupedProduct,
    required String newItemName,
    required String newModel,
  });
  Future<Either<Failure, void>> deleteProduct(String productId);
  Future<Either<Failure, void>> clearAllProducts();
}

