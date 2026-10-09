import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/inventory/data/models/product_model.dart';
import 'package:gear_track/feature/inventory/data/sources/inventory_remote_data_source.dart';
import 'package:gear_track/feature/inventory/domain/entities/grouped_product.dart';
import 'package:gear_track/feature/inventory/domain/entities/product.dart';
import 'package:gear_track/feature/inventory/domain/repository/inventory_repository.dart';
import 'package:fpdart/fpdart.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource remoteDataSource;

  InventoryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> addProduct(Product product) async {
    try {
      final productModel = ProductModel.fromEntity(product);
      await remoteDataSource.addProduct(productModel);
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(Failure(e.message ?? e.toString()));
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      return Left(Failure(msg));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    try {
      final productModels = await remoteDataSource.getProducts();
      return Right(productModels);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProduct(Product product) async {
    try {
      final productModel = ProductModel.fromEntity(product);
      await remoteDataSource.updateProduct(productModel);
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateGroupedProductDetails({
    required GroupedProduct groupedProduct,
    required String newItemName,
    required String newModel,
  }) async {
    try {
      await remoteDataSource.updateGroupedProductDetails(
        groupedProduct: groupedProduct,
        newItemName: newItemName,
        newModel: newModel,
      );
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String productId) async {
    try {
      await remoteDataSource.deleteProduct(productId);
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearAllProducts() async {
    try {
      await remoteDataSource.clearAllProducts();
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}

