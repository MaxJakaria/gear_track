import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/product_of_sales/domain/entities/sale_entity.dart';
import 'package:gear_track/feature/product_of_sales/domain/repository/pos_repository.dart';

class GetProductSales {
  final PosRepository repository;

  GetProductSales(this.repository);

  Future<Either<Failure, List<SaleEntity>>> call(String productId) async {
    return await repository.getProductSales(productId);
  }
}
