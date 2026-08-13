import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/product_of_sales/domain/entities/sale_entity.dart';

abstract class PosRepository {
  Future<Either<Failure, void>> addSale(SaleEntity saleEntity);

  Future<Either<Failure, List<SaleEntity>>> getSales();

  Future<Either<Failure, List<SaleEntity>>> getProductSales(String productId);
}
