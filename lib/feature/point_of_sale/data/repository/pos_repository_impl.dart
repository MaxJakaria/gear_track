import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/point_of_sale/data/models/sale_model.dart';
import 'package:gear_track/feature/point_of_sale/data/sources/pos_remote_data_source.dart';
import 'package:gear_track/feature/point_of_sale/domain/entities/sale_entity.dart';
import 'package:gear_track/feature/point_of_sale/domain/repository/pos_repository.dart';
import 'package:gear_track/feature/receipt_verification/data/models/invoice_model.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';

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
  Future<Either<Failure, void>> checkoutCart({
    required List<SaleEntity> sales,
    required InvoiceEntity invoice,
  }) async {
    try {
      final saleModels = sales.map((s) => SaleModel.fromEntity(s)).toList();
      final invoiceModel = invoice is InvoiceModel
          ? invoice
          : InvoiceModel(
              invoiceId: invoice.invoiceId,
              saleDate: invoice.saleDate,
              totalAmount: invoice.totalAmount,
              totalItems: invoice.totalItems,
              items: invoice.items,
              shopName: invoice.shopName,
              shopPhone: invoice.shopPhone,
              shopAddress: invoice.shopAddress,
            );

      await remoteDataSource.checkoutCart(
        sales: saleModels,
        invoice: invoiceModel,
      );
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

  @override
  Future<Either<Failure, List<SaleEntity>>> getProductSales(
    String productId,
  ) async {
    try {
      final saleModels = await remoteDataSource.getProductSales(productId);
      return Right(saleModels);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveInvoice(InvoiceEntity invoice) async {
    try {
      final invoiceModel = invoice is InvoiceModel
          ? invoice
          : InvoiceModel(
              invoiceId: invoice.invoiceId,
              saleDate: invoice.saleDate,
              totalAmount: invoice.totalAmount,
              totalItems: invoice.totalItems,
              items: invoice.items,
              shopName: invoice.shopName,
              shopPhone: invoice.shopPhone,
              shopAddress: invoice.shopAddress,
            );
      await remoteDataSource.saveInvoice(invoiceModel);
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}
