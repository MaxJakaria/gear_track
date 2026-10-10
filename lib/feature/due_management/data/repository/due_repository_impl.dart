import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/due_management/data/sources/due_remote_data_source.dart';
import 'package:gear_track/feature/due_management/domain/repository/due_repository.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';

class DueRepositoryImpl implements DueRepository {
  final DueRemoteDataSource remoteDataSource;

  DueRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getDueInvoices() async {
    try {
      final models = await remoteDataSource.getDueInvoices();
      return right(models);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, InvoiceEntity>> collectDuePayment(
    String invoiceId,
    double paymentAmount,
  ) async {
    try {
      final updatedModel = await remoteDataSource.collectDuePayment(
        invoiceId,
        paymentAmount,
      );
      return right(updatedModel);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}
