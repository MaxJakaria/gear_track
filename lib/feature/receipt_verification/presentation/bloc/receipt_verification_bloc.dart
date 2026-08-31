import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';
import 'package:gear_track/feature/receipt_verification/domain/usecases/verify_receipt.dart';

part 'receipt_verification_event.dart';
part 'receipt_verification_state.dart';

class ReceiptVerificationBloc
    extends Bloc<ReceiptVerificationEvent, ReceiptVerificationState> {
  final VerifyReceipt verifyReceipt;

  ReceiptVerificationBloc({required this.verifyReceipt})
      : super(ReceiptVerificationInitial()) {
    on<VerifyReceiptCodeEvent>(_onVerifyReceiptCode);
    on<ResetReceiptVerificationEvent>(_onResetReceiptVerification);
  }

  Future<void> _onVerifyReceiptCode(
    VerifyReceiptCodeEvent event,
    Emitter<ReceiptVerificationState> emit,
  ) async {
    final cleanCode = event.rawCode.trim();
    if (cleanCode.isEmpty) {
      emit(
        const ReceiptVerificationFailure(
          errorMessage: 'Please enter or scan a valid Receipt ID / QR Code.',
          scannedCode: '',
        ),
      );
      return;
    }

    emit(ReceiptVerificationLoading(checkingCode: cleanCode));

    final result = await verifyReceipt(cleanCode);

    result.fold(
      (failure) => emit(
        ReceiptVerificationFailure(
          errorMessage: failure.message,
          scannedCode: cleanCode,
        ),
      ),
      (data) => emit(
        ReceiptVerificationSuccess(
          invoice: data.invoice,
          message: data.statusMessage,
        ),
      ),
    );
  }

  void _onResetReceiptVerification(
    ResetReceiptVerificationEvent event,
    Emitter<ReceiptVerificationState> emit,
  ) {
    emit(ReceiptVerificationInitial());
  }
}
