import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/receipt_verification/data/sources/receipt_verification_remote_data_source.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';
import 'package:gear_track/feature/receipt_verification/domain/repository/receipt_verification_repository.dart';

class ReceiptVerificationRepositoryImpl
    implements ReceiptVerificationRepository {
  final ReceiptVerificationRemoteDataSource remoteDataSource;

  ReceiptVerificationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, InvoiceEntity?>> verifyReceipt(String invoiceId) async {
    try {
      final invoice = await remoteDataSource.getInvoice(invoiceId);
      return Right(invoice);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}
