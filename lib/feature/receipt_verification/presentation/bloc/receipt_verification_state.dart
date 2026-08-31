part of 'receipt_verification_bloc.dart';

sealed class ReceiptVerificationState extends Equatable {
  const ReceiptVerificationState();

  @override
  List<Object?> get props => [];
}

final class ReceiptVerificationInitial extends ReceiptVerificationState {}

final class ReceiptVerificationLoading extends ReceiptVerificationState {
  final String checkingCode;

  const ReceiptVerificationLoading({this.checkingCode = ''});

  @override
  List<Object?> get props => [checkingCode];
}

final class ReceiptVerificationSuccess extends ReceiptVerificationState {
  final InvoiceEntity invoice;
  final String message;

  const ReceiptVerificationSuccess({
    required this.invoice,
    this.message = 'Authentic Receipt Verified in GearTrack Cloud Database.',
  });

  @override
  List<Object?> get props => [invoice, message];
}

final class ReceiptVerificationFailure extends ReceiptVerificationState {
  final String errorMessage;
  final String scannedCode;

  const ReceiptVerificationFailure({
    required this.errorMessage,
    this.scannedCode = '',
  });

  @override
  List<Object?> get props => [errorMessage, scannedCode];
}
