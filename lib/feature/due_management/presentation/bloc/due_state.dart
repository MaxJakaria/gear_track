import 'package:equatable/equatable.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';

abstract class DueState extends Equatable {
  const DueState();

  @override
  List<Object?> get props => [];
}

class DueInitial extends DueState {
  const DueInitial();
}

class DueLoading extends DueState {
  const DueLoading();
}

class DueLoaded extends DueState {
  final List<InvoiceEntity> allInvoices;
  final List<InvoiceEntity> filteredInvoices;
  final String searchQuery;
  final double totalOutstandingDue;

  const DueLoaded({
    required this.allInvoices,
    required this.filteredInvoices,
    this.searchQuery = '',
    required this.totalOutstandingDue,
  });

  double get filteredDue => filteredInvoices.fold<double>(
        0.0,
        (sum, inv) => sum + inv.dueAmount,
      );

  double get grandTotalDue => allInvoices.fold<double>(
        0.0,
        (sum, inv) => sum + inv.dueAmount,
      );

  bool get isSearching => searchQuery.trim().isNotEmpty;

  DueLoaded copyWith({
    List<InvoiceEntity>? allInvoices,
    List<InvoiceEntity>? filteredInvoices,
    String? searchQuery,
    double? totalOutstandingDue,
  }) {
    return DueLoaded(
      allInvoices: allInvoices ?? this.allInvoices,
      filteredInvoices: filteredInvoices ?? this.filteredInvoices,
      searchQuery: searchQuery ?? this.searchQuery,
      totalOutstandingDue: totalOutstandingDue ?? this.totalOutstandingDue,
    );
  }

  @override
  List<Object?> get props => [
        allInvoices,
        filteredInvoices,
        searchQuery,
        totalOutstandingDue,
      ];
}

class DuePaymentProcessing extends DueState {
  final String invoiceId;

  const DuePaymentProcessing(this.invoiceId);

  @override
  List<Object?> get props => [invoiceId];
}

class DuePaymentSuccess extends DueState {
  final InvoiceEntity updatedInvoice;
  final double collectedAmount;

  const DuePaymentSuccess({
    required this.updatedInvoice,
    required this.collectedAmount,
  });

  @override
  List<Object?> get props => [updatedInvoice, collectedAmount];
}

class DueError extends DueState {
  final String message;

  const DueError(this.message);

  @override
  List<Object?> get props => [message];
}
