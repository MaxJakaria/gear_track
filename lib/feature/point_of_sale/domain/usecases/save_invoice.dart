import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/point_of_sale/domain/repository/pos_repository.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';

class SaveInvoice {
  final PosRepository repository;

  SaveInvoice(this.repository);

  Future<Either<Failure, void>> call(InvoiceEntity invoice) async {
    return await repository.saveInvoice(invoice);
  }
}
