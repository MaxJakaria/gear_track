import 'package:equatable/equatable.dart';
import 'package:gear_track/feature/returns/domain/entities/return_entity.dart';

abstract class ReturnEvent extends Equatable {
  const ReturnEvent();

  @override
  List<Object?> get props => [];
}

class FetchReturnsEvent extends ReturnEvent {
  const FetchReturnsEvent();
}

class FetchInvoiceForReturnEvent extends ReturnEvent {
  final String invoiceId;

  const FetchInvoiceForReturnEvent(this.invoiceId);

  @override
  List<Object?> get props => [invoiceId];
}

class ProcessReturnEvent extends ReturnEvent {
  final ReturnEntity returnRecord;

  const ProcessReturnEvent(this.returnRecord);

  @override
  List<Object?> get props => [returnRecord];
}

class ResetReturnStateEvent extends ReturnEvent {
  const ResetReturnStateEvent();
}
