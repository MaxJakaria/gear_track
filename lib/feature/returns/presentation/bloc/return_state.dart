import 'package:equatable/equatable.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';
import 'package:gear_track/feature/returns/domain/entities/return_entity.dart';

abstract class ReturnState extends Equatable {
  const ReturnState();

  @override
  List<Object?> get props => [];
}

class ReturnInitial extends ReturnState {}

class ReturnLoading extends ReturnState {
  final String? loadingMessage;

  const ReturnLoading({this.loadingMessage});

  @override
  List<Object?> get props => [loadingMessage];
}

class ReturnsLoadedSuccess extends ReturnState {
  final List<ReturnEntity> returns;

  const ReturnsLoadedSuccess(this.returns);

  double get totalRefundsAllTime =>
      returns.fold(0.0, (sum, r) => sum + r.totalRefundAmount);

  int get totalItemsReturnedAllTime =>
      returns.fold(0, (sum, r) => sum + r.totalQuantity);

  @override
  List<Object?> get props => [returns];
}

class InvoiceLoadedForReturnSuccess extends ReturnState {
  final InvoiceEntity invoice;

  const InvoiceLoadedForReturnSuccess(this.invoice);

  @override
  List<Object?> get props => [invoice];
}

class ReturnProcessedSuccess extends ReturnState {
  final ReturnEntity returnRecord;

  const ReturnProcessedSuccess(this.returnRecord);

  @override
  List<Object?> get props => [returnRecord];
}

class ReturnFailure extends ReturnState {
  final String errorMessage;

  const ReturnFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
