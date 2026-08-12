import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/product_of_sales/domain/entities/sale_entity.dart';
import 'package:gear_track/feature/product_of_sales/domain/repository/pos_repository.dart';

class AddSale {
  final PosRepository repository;

  AddSale(this.repository);

  Future<Either<Failure, void>> call(SaleEntity saleEntity) async {
    return await repository.addSale(saleEntity);
  }
}
