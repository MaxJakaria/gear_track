import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';
import 'package:gear_track/feature/returns/domain/repository/return_repository.dart';

class GetInvoiceForReturn {
  final ReturnRepository repository;

  GetInvoiceForReturn(this.repository);

  Future<Either<Failure, InvoiceEntity>> call(String invoiceId) async {
    final cleanId = invoiceId.trim();
    if (cleanId.isEmpty) {
      return Left(Failure('Please enter a valid Invoice ID.'));
    }
    return await repository.getInvoiceForReturn(cleanId);
  }
}
