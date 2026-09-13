import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';
import 'package:gear_track/feature/returns/domain/entities/paginated_returns_entity.dart';
import 'package:gear_track/feature/returns/domain/entities/return_entity.dart';

abstract class ReturnRepository {
  Future<Either<Failure, ReturnEntity>> processReturn(ReturnEntity returnEntity);
  Future<Either<Failure, PaginatedReturnsEntity>> getReturns({
    int page = 1,
    int pageSize = 10,
  });
  Future<Either<Failure, InvoiceEntity>> getInvoiceForReturn(String invoiceId);
  Future<Either<Failure, List<InvoiceEntity>>> searchInvoicesForReturn(String query);
}
