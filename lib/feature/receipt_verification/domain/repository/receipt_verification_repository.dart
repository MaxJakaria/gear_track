import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';

abstract class ReceiptVerificationRepository {
  Future<Either<Failure, InvoiceEntity?>> verifyReceipt(String invoiceId);
}
