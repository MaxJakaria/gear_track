import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/product_of_sales/data/models/sale_model.dart';
import 'package:gear_track/feature/product_of_sales/data/sources/pos_remote_data_source.dart';
import 'package:gear_track/feature/product_of_sales/domain/entities/sale_entity.dart';
import 'package:gear_track/feature/product_of_sales/domain/repository/pos_repository.dart';

class PosRepositoryImpl implements PosRepository {
  final PosRemoteDataSource remoteDataSource;

  PosRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> addSale(SaleEntity saleEntity) async {
    try {
      final saleModel = SaleModel.fromEntity(saleEntity);
      await remoteDataSource.addSale(saleModel);
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SaleEntity>>> getSales() async {
    try {
      final saleModels = await remoteDataSource.getSales();
      return Right(saleModels);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}
