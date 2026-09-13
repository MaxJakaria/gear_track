import 'package:equatable/equatable.dart';
import 'package:gear_track/feature/returns/domain/entities/return_entity.dart';

abstract class ReturnEvent extends Equatable {
  const ReturnEvent();

  @override
  List<Object?> get props => [];
}

class FetchReturnsEvent extends ReturnEvent {
  final int page;
  final bool forceRefresh;

  const FetchReturnsEvent({
    this.page = 1,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [page, forceRefresh];
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

class SearchInvoicesForReturnEvent extends ReturnEvent {
  final String query;

  const SearchInvoicesForReturnEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class ClearInvoiceSearchEvent extends ReturnEvent {
  const ClearInvoiceSearchEvent();
}
