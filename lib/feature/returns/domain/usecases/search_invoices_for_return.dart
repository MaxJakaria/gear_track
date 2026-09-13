import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';
import 'package:gear_track/feature/returns/domain/repository/return_repository.dart';

/// Use case to search sold invoices for return strictly by Customer Name (partyName) or Invoice ID (invoiceId).
class SearchInvoicesForReturn {
  final ReturnRepository repository;

  SearchInvoicesForReturn(this.repository);

  Future<Either<Failure, List<InvoiceEntity>>> call(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      return const Right([]);
    }
    return await repository.searchInvoicesForReturn(clean);
  }
}
