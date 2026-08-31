part of 'receipt_verification_bloc.dart';

sealed class ReceiptVerificationEvent extends Equatable {
  const ReceiptVerificationEvent();

  @override
  List<Object?> get props => [];
}

final class VerifyReceiptCodeEvent extends ReceiptVerificationEvent {
  final String rawCode;

  const VerifyReceiptCodeEvent(this.rawCode);

  @override
  List<Object?> get props => [rawCode];
}

final class ResetReceiptVerificationEvent extends ReceiptVerificationEvent {}
