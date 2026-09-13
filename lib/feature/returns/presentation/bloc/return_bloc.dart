import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/feature/returns/domain/entities/return_entity.dart';
import 'package:gear_track/feature/returns/domain/usecases/get_invoice_for_return.dart';
import 'package:gear_track/feature/returns/domain/usecases/get_returns.dart';
import 'package:gear_track/feature/returns/domain/usecases/process_return.dart';
import 'package:gear_track/feature/returns/domain/usecases/search_invoices_for_return.dart';
import 'package:gear_track/feature/returns/presentation/bloc/return_event.dart';
import 'package:gear_track/feature/returns/presentation/bloc/return_state.dart';

class ReturnBloc extends Bloc<ReturnEvent, ReturnState> {
  final ProcessReturn processReturn;
  final GetReturns getReturns;
  final GetInvoiceForReturn getInvoiceForReturn;
  final SearchInvoicesForReturn searchInvoicesForReturn;

  final Map<int, List<ReturnEntity>> _pagedReturns = {};
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  double _totalRefundsAllTime = 0.0;
  int _totalItemsReturnedAllTime = 0;
  bool _hasMore = false;

  ReturnBloc({
    required this.processReturn,
    required this.getReturns,
    required this.getInvoiceForReturn,
    required this.searchInvoicesForReturn,
  }) : super(ReturnInitial()) {
    on<FetchReturnsEvent>(_onFetchReturns);
    on<FetchInvoiceForReturnEvent>(_onFetchInvoiceForReturn);
    on<ProcessReturnEvent>(_onProcessReturn);
    on<ResetReturnStateEvent>(_onResetReturnState);
    on<SearchInvoicesForReturnEvent>(_onSearchInvoicesForReturn);
    on<ClearInvoiceSearchEvent>(_onClearInvoiceSearch);
  }

  Future<void> _onFetchReturns(
    FetchReturnsEvent event,
    Emitter<ReturnState> emit,
  ) async {
    final page = event.page;
    final forceRefresh = event.forceRefresh;

    if (forceRefresh) {
      _pagedReturns.clear();
    }

    // Fast-path: if page is already cached in memory, emit immediately with 0 database reads!
    if (!forceRefresh && _pagedReturns.containsKey(page)) {
      _currentPage = page;
      if (state is ReturnsLoadedSuccess) {
        emit((state as ReturnsLoadedSuccess).copyWith(
          returns: _pagedReturns[page],
          currentPage: _currentPage,
          totalPages: _totalPages,
          totalCount: _totalCount,
          totalRefundsAllTime: _totalRefundsAllTime,
          totalItemsReturnedAllTime: _totalItemsReturnedAllTime,
          hasMore: _hasMore,
          isHistoryLoading: false,
        ));
      } else {
        emit(ReturnsLoadedSuccess(
          _pagedReturns[page]!,
          currentPage: _currentPage,
          totalPages: _totalPages,
          totalCount: _totalCount,
          totalRefundsAllTime: _totalRefundsAllTime,
          totalItemsReturnedAllTime: _totalItemsReturnedAllTime,
          hasMore: _hasMore,
        ));
      }
      return;
    }

    // Show loading: inline indicator if already showing results, otherwise full loading
    if (state is ReturnsLoadedSuccess) {
      emit((state as ReturnsLoadedSuccess).copyWith(
        isHistoryLoading: true,
      ));
    } else {
      emit(const ReturnLoading(loadingMessage: 'Loading returns history...'));
    }

    final result = await getReturns(page: page, pageSize: 10);
    result.fold(
      (failure) {
        if (state is ReturnsLoadedSuccess) {
          emit((state as ReturnsLoadedSuccess).copyWith(
            isHistoryLoading: false,
          ));
        } else {
          emit(ReturnFailure(failure.message));
        }
      },
      (paginated) {
        _currentPage = paginated.currentPage;
        _totalPages = paginated.totalPages;
        _totalCount = paginated.totalCount;
        _totalRefundsAllTime = paginated.totalRefundsAllTime;
        _totalItemsReturnedAllTime = paginated.totalItemsReturnedAllTime;
        _hasMore = paginated.hasMore;
        _pagedReturns[_currentPage] = paginated.returns;

        if (state is ReturnsLoadedSuccess) {
          emit((state as ReturnsLoadedSuccess).copyWith(
            returns: paginated.returns,
            currentPage: _currentPage,
            totalPages: _totalPages,
            totalCount: _totalCount,
            totalRefundsAllTime: _totalRefundsAllTime,
            totalItemsReturnedAllTime: _totalItemsReturnedAllTime,
            hasMore: _hasMore,
            isHistoryLoading: false,
          ));
        } else {
          emit(ReturnsLoadedSuccess(
            paginated.returns,
            currentPage: _currentPage,
            totalPages: _totalPages,
            totalCount: _totalCount,
            totalRefundsAllTime: _totalRefundsAllTime,
            totalItemsReturnedAllTime: _totalItemsReturnedAllTime,
            hasMore: _hasMore,
          ));
        }
      },
    );
  }

  Future<void> _onFetchInvoiceForReturn(
    FetchInvoiceForReturnEvent event,
    Emitter<ReturnState> emit,
  ) async {
    emit(const ReturnLoading(loadingMessage: 'Fetching invoice details...'));
    final result = await getInvoiceForReturn(event.invoiceId);
    result.fold(
      (failure) => emit(ReturnFailure(failure.message)),
      (invoice) => emit(InvoiceLoadedForReturnSuccess(invoice)),
    );
  }

  Future<void> _onProcessReturn(
    ProcessReturnEvent event,
    Emitter<ReturnState> emit,
  ) async {
    emit(const ReturnLoading(loadingMessage: 'Processing return & updating stock...'));
    final result = await processReturn(event.returnRecord);
    result.fold(
      (failure) => emit(ReturnFailure(failure.message)),
      (record) {
        // Invalidate cached pages so newly created return appears on Page 1
        _pagedReturns.clear();
        emit(ReturnProcessedSuccess(record));
      },
    );
  }

  void _onResetReturnState(
    ResetReturnStateEvent event,
    Emitter<ReturnState> emit,
  ) {
    if (_pagedReturns.containsKey(_currentPage)) {
      emit(ReturnsLoadedSuccess(
        _pagedReturns[_currentPage]!,
        currentPage: _currentPage,
        totalPages: _totalPages,
        totalCount: _totalCount,
        totalRefundsAllTime: _totalRefundsAllTime,
        totalItemsReturnedAllTime: _totalItemsReturnedAllTime,
        hasMore: _hasMore,
      ));
    } else {
      emit(ReturnInitial());
    }
  }

  Future<void> _onSearchInvoicesForReturn(
    SearchInvoicesForReturnEvent event,
    Emitter<ReturnState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      if (state is ReturnsLoadedSuccess) {
        emit((state as ReturnsLoadedSuccess).copyWith(
          clearSearchedInvoices: true,
          isSearchingInvoice: false,
          searchQuery: '',
          searchError: null,
        ));
      }
      return;
    }

    final currentReturns = _pagedReturns[_currentPage] ?? [];

    if (state is ReturnsLoadedSuccess) {
      emit((state as ReturnsLoadedSuccess).copyWith(
        isSearchingInvoice: true,
        searchQuery: query,
        searchError: null,
      ));
    } else {
      emit(ReturnsLoadedSuccess(
        currentReturns,
        currentPage: _currentPage,
        totalPages: _totalPages,
        totalCount: _totalCount,
        totalRefundsAllTime: _totalRefundsAllTime,
        totalItemsReturnedAllTime: _totalItemsReturnedAllTime,
        hasMore: _hasMore,
        isSearchingInvoice: true,
        searchQuery: query,
      ));
    }

    final result = await searchInvoicesForReturn(query);
    result.fold(
      (failure) {
        if (state is ReturnsLoadedSuccess) {
          emit((state as ReturnsLoadedSuccess).copyWith(
            isSearchingInvoice: false,
            searchedInvoices: [],
            searchError: failure.message,
          ));
        } else {
          emit(ReturnsLoadedSuccess(
            currentReturns,
            currentPage: _currentPage,
            totalPages: _totalPages,
            totalCount: _totalCount,
            totalRefundsAllTime: _totalRefundsAllTime,
            totalItemsReturnedAllTime: _totalItemsReturnedAllTime,
            hasMore: _hasMore,
            isSearchingInvoice: false,
            searchedInvoices: [],
            searchQuery: query,
            searchError: failure.message,
          ));
        }
      },
      (invoices) {
        if (state is ReturnsLoadedSuccess) {
          emit((state as ReturnsLoadedSuccess).copyWith(
            isSearchingInvoice: false,
            searchedInvoices: invoices,
            searchError: null,
          ));
        } else {
          emit(ReturnsLoadedSuccess(
            currentReturns,
            currentPage: _currentPage,
            totalPages: _totalPages,
            totalCount: _totalCount,
            totalRefundsAllTime: _totalRefundsAllTime,
            totalItemsReturnedAllTime: _totalItemsReturnedAllTime,
            hasMore: _hasMore,
            isSearchingInvoice: false,
            searchedInvoices: invoices,
            searchQuery: query,
          ));
        }
      },
    );
  }

  void _onClearInvoiceSearch(
    ClearInvoiceSearchEvent event,
    Emitter<ReturnState> emit,
  ) {
    if (state is ReturnsLoadedSuccess) {
      emit((state as ReturnsLoadedSuccess).copyWith(
        clearSearchedInvoices: true,
        isSearchingInvoice: false,
        searchQuery: '',
        searchError: null,
      ));
    }
  }
}
