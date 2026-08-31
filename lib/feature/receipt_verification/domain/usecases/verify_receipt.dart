import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';
import 'package:gear_track/feature/receipt_verification/domain/repository/receipt_verification_repository.dart';

class VerifyReceiptResult {
  final InvoiceEntity invoice;
  final bool isAuthentic;
  final String statusMessage;

  const VerifyReceiptResult({
    required this.invoice,
    required this.isAuthentic,
    required this.statusMessage,
  });
}

class VerifyReceipt {
  final ReceiptVerificationRepository repository;

  VerifyReceipt(this.repository);

  static String extractInvoiceId(String rawInput) {
    final input = rawInput.trim();
    if (input.isEmpty) return '';

    // Handle structured format: GT-RECEIPT|ID:GT-20260831-1234|DATE:...
    if (input.contains('|')) {
      final parts = input.split('|');
      for (final part in parts) {
        final p = part.trim();
        if (p.toUpperCase().startsWith('ID:')) {
          return p.substring(3).trim();
        }
      }
    }

    // Handle key-value format: ID=GT-20260831-1234
    if (input.contains('id=') || input.contains('ID=')) {
      final match = RegExp(r'(?:id|ID)=([^&|\s]+)').firstMatch(input);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim();
      }
    }

    // Plain ID input (e.g. GT-20260831-1234 or INV-20260831-1234)
    return input;
  }

  Future<Either<Failure, VerifyReceiptResult>> call(String rawQrOrId) async {
    final invoiceId = extractInvoiceId(rawQrOrId);

    if (invoiceId.isEmpty) {
      return Left(Failure('Invalid barcode or receipt code format.'));
    }

    final result = await repository.verifyReceipt(invoiceId);

    return result.fold(
      (failure) => Left(failure),
      (invoice) {
        if (invoice == null) {
          return Left(
            Failure(
              'No authentic record found for Receipt ID: $invoiceId. This receipt may be counterfeit or invalid.',
            ),
          );
        }

        return Right(
          VerifyReceiptResult(
            invoice: invoice,
            isAuthentic: true,
            statusMessage: 'Authentic Receipt Verified in GearTrack Cloud Database.',
          ),
        );
      },
    );
  }
}
