import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';
import 'package:gear_track/feature/returns/domain/entities/return_entity.dart';

abstract class ReturnRepository {
  Future<Either<Failure, ReturnEntity>> processReturn(ReturnEntity returnEntity);
  Future<Either<Failure, List<ReturnEntity>>> getReturns();
  Future<Either<Failure, InvoiceEntity>> getInvoiceForReturn(String invoiceId);
}
