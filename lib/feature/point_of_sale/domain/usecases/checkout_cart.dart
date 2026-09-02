import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/point_of_sale/domain/entities/sale_entity.dart';
import 'package:gear_track/feature/point_of_sale/domain/repository/pos_repository.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';

class CheckoutCart {
  final PosRepository repository;

  CheckoutCart(this.repository);

  Future<Either<Failure, void>> call({
    required List<SaleEntity> sales,
    required InvoiceEntity invoice,
  }) async {
    return await repository.checkoutCart(
      sales: sales,
      invoice: invoice,
    );
  }
}
