import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';

abstract class DueRepository {
  Future<Either<Failure, List<InvoiceEntity>>> getDueInvoices();
  Future<Either<Failure, InvoiceEntity>> collectDuePayment(
    String invoiceId,
    double paymentAmount,
  );
}
