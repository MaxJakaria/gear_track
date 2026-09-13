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
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final double totalRefundsAllTime;
  final int totalItemsReturnedAllTime;
  final bool hasMore;
  final bool isHistoryLoading;
  final List<InvoiceEntity>? searchedInvoices;
  final bool isSearchingInvoice;
  final String searchQuery;
  final String? searchError;

  const ReturnsLoadedSuccess(
    this.returns, {
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalCount = 0,
    this.totalRefundsAllTime = 0.0,
    this.totalItemsReturnedAllTime = 0,
    this.hasMore = false,
    this.isHistoryLoading = false,
    this.searchedInvoices,
    this.isSearchingInvoice = false,
    this.searchQuery = '',
    this.searchError,
  });

  bool get hasSearched => searchedInvoices != null;

  ReturnsLoadedSuccess copyWith({
    List<ReturnEntity>? returns,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    double? totalRefundsAllTime,
    int? totalItemsReturnedAllTime,
    bool? hasMore,
    bool? isHistoryLoading,
    List<InvoiceEntity>? searchedInvoices,
    bool? isSearchingInvoice,
    String? searchQuery,
    String? searchError,
    bool clearSearchedInvoices = false,
  }) {
    return ReturnsLoadedSuccess(
      returns ?? this.returns,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      totalRefundsAllTime: totalRefundsAllTime ?? this.totalRefundsAllTime,
      totalItemsReturnedAllTime:
          totalItemsReturnedAllTime ?? this.totalItemsReturnedAllTime,
      hasMore: hasMore ?? this.hasMore,
      isHistoryLoading: isHistoryLoading ?? this.isHistoryLoading,
      searchedInvoices: clearSearchedInvoices
          ? null
          : (searchedInvoices ?? this.searchedInvoices),
      isSearchingInvoice: isSearchingInvoice ?? this.isSearchingInvoice,
      searchQuery: searchQuery ?? this.searchQuery,
      searchError: searchError,
    );
  }

  @override
  List<Object?> get props => [
        returns,
        currentPage,
        totalPages,
        totalCount,
        totalRefundsAllTime,
        totalItemsReturnedAllTime,
        hasMore,
        isHistoryLoading,
        searchedInvoices,
        isSearchingInvoice,
        searchQuery,
        searchError,
      ];
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
