import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/feature/due_management/domain/repository/due_repository.dart';
import 'package:gear_track/feature/due_management/presentation/bloc/due_event.dart';
import 'package:gear_track/feature/due_management/presentation/bloc/due_state.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';

class DueBloc extends Bloc<DueEvent, DueState> {
  final DueRepository dueRepository;

  DueBloc({required this.dueRepository}) : super(const DueInitial()) {
    on<FetchDueInvoicesEvent>(_onFetchDueInvoices);
    on<SearchDueInvoicesEvent>(_onSearchDueInvoices);
    on<CollectDuePaymentEvent>(_onCollectDuePayment);
  }

  Future<void> _onFetchDueInvoices(
    FetchDueInvoicesEvent event,
    Emitter<DueState> emit,
  ) async {
    emit(const DueLoading());
    final result = await dueRepository.getDueInvoices();

    result.fold(
      (failure) => emit(DueError(failure.message)),
      (invoices) {
        final totalDue = invoices.fold<double>(
          0.0,
          (sum, inv) => sum + inv.dueAmount,
        );
        emit(DueLoaded(
          allInvoices: invoices,
          filteredInvoices: invoices,
          totalOutstandingDue: totalDue,
        ));
      },
    );
  }

  void _onSearchDueInvoices(
    SearchDueInvoicesEvent event,
    Emitter<DueState> emit,
  ) {
    if (state is DueLoaded) {
      final currentState = state as DueLoaded;
      final q = event.query.trim().toLowerCase();

      if (q.isEmpty) {
        final allDue = currentState.allInvoices.fold<double>(
          0.0,
          (sum, inv) => sum + inv.dueAmount,
        );
        emit(currentState.copyWith(
          filteredInvoices: currentState.allInvoices,
          searchQuery: '',
          totalOutstandingDue: allDue,
        ));
        return;
      }

      final filtered = currentState.allInvoices.where((inv) {
        final partyMatch = inv.partyName.toLowerCase().contains(q);
        final invIdMatch = inv.invoiceId.toLowerCase().contains(q);
        final addressMatch = inv.partyAddress.toLowerCase().contains(q);
        final servedByMatch = inv.servedBy.toLowerCase().contains(q);
        return partyMatch || invIdMatch || addressMatch || servedByMatch;
      }).toList();

      final filteredDue = filtered.fold<double>(
        0.0,
        (sum, inv) => sum + inv.dueAmount,
      );

      emit(currentState.copyWith(
        filteredInvoices: filtered,
        searchQuery: event.query,
        totalOutstandingDue: filteredDue,
      ));
    }
  }

  Future<void> _onCollectDuePayment(
    CollectDuePaymentEvent event,
    Emitter<DueState> emit,
  ) async {
    List<InvoiceEntity> currentAll = [];
    String currentQuery = '';

    if (state is DueLoaded) {
      final s = state as DueLoaded;
      currentAll = s.allInvoices;
      currentQuery = s.searchQuery;
    }

    emit(DuePaymentProcessing(event.invoiceId));

    final result = await dueRepository.collectDuePayment(
      event.invoiceId,
      event.paymentAmount,
    );

    await result.fold(
      (failure) async {
        emit(DueError(failure.message));
        // Reload list to recover state
        add(const FetchDueInvoicesEvent());
      },
      (updatedInvoice) async {
        emit(DuePaymentSuccess(
          updatedInvoice: updatedInvoice,
          collectedAmount: event.paymentAmount,
        ));

        // Update list
        final updatedList = currentAll
            .map((inv) => inv.invoiceId == updatedInvoice.invoiceId ? updatedInvoice : inv)
            .where((inv) => inv.dueAmount > 0.001)
            .toList();

        final q = currentQuery.trim().toLowerCase();
        final filtered = q.isEmpty
            ? updatedList
            : updatedList.where((inv) {
                return inv.partyName.toLowerCase().contains(q) ||
                    inv.invoiceId.toLowerCase().contains(q) ||
                    inv.partyAddress.toLowerCase().contains(q);
              }).toList();

        final filteredDue = filtered.fold<double>(
          0.0,
          (sum, inv) => sum + inv.dueAmount,
        );

        emit(DueLoaded(
          allInvoices: updatedList,
          filteredInvoices: filtered,
          searchQuery: currentQuery,
          totalOutstandingDue: filteredDue,
        ));
      },
    );
  }
}
