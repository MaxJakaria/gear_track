import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/point_of_sale/domain/entities/sale_entity.dart';
import 'package:gear_track/feature/point_of_sale/domain/repository/pos_repository.dart';

class GetSales {
  final PosRepository repository;

  GetSales(this.repository);

  Future<Either<Failure, List<SaleEntity>>> call() async {
    return await repository.getSales();
  }
}
