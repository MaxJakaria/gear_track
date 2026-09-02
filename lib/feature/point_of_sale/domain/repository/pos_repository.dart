import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/point_of_sale/domain/entities/sale_entity.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';

abstract class PosRepository {
  Future<Either<Failure, void>> addSale(SaleEntity saleEntity);

  Future<Either<Failure, void>> checkoutCart({
    required List<SaleEntity> sales,
    required InvoiceEntity invoice,
  });

  Future<Either<Failure, List<SaleEntity>>> getSales();

  Future<Either<Failure, List<SaleEntity>>> getProductSales(String productId);

  Future<Either<Failure, void>> saveInvoice(InvoiceEntity invoice);
}
