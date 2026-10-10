import 'package:equatable/equatable.dart';

abstract class DueEvent extends Equatable {
  const DueEvent();

  @override
  List<Object?> get props => [];
}

class FetchDueInvoicesEvent extends DueEvent {
  const FetchDueInvoicesEvent();
}

class CollectDuePaymentEvent extends DueEvent {
  final String invoiceId;
  final double paymentAmount;

  const CollectDuePaymentEvent({
    required this.invoiceId,
    required this.paymentAmount,
  });

  @override
  List<Object?> get props => [invoiceId, paymentAmount];
}

class SearchDueInvoicesEvent extends DueEvent {
  final String query;

  const SearchDueInvoicesEvent(this.query);

  @override
  List<Object?> get props => [query];
}
