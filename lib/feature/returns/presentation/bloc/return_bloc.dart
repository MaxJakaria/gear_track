import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/feature/returns/domain/usecases/get_invoice_for_return.dart';
import 'package:gear_track/feature/returns/domain/usecases/get_returns.dart';
import 'package:gear_track/feature/returns/domain/usecases/process_return.dart';
import 'package:gear_track/feature/returns/presentation/bloc/return_event.dart';
import 'package:gear_track/feature/returns/presentation/bloc/return_state.dart';

class ReturnBloc extends Bloc<ReturnEvent, ReturnState> {
  final ProcessReturn processReturn;
  final GetReturns getReturns;
  final GetInvoiceForReturn getInvoiceForReturn;

  ReturnBloc({
    required this.processReturn,
    required this.getReturns,
    required this.getInvoiceForReturn,
  }) : super(ReturnInitial()) {
    on<FetchReturnsEvent>(_onFetchReturns);
    on<FetchInvoiceForReturnEvent>(_onFetchInvoiceForReturn);
    on<ProcessReturnEvent>(_onProcessReturn);
    on<ResetReturnStateEvent>(_onResetReturnState);
  }

  Future<void> _onFetchReturns(
    FetchReturnsEvent event,
    Emitter<ReturnState> emit,
  ) async {
    emit(const ReturnLoading(loadingMessage: 'Loading returns history...'));
    final result = await getReturns();
    result.fold(
      (failure) => emit(ReturnFailure(failure.message)),
      (returns) => emit(ReturnsLoadedSuccess(returns)),
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
      (record) => emit(ReturnProcessedSuccess(record)),
    );
  }

  void _onResetReturnState(
    ResetReturnStateEvent event,
    Emitter<ReturnState> emit,
  ) {
    emit(ReturnInitial());
  }
}
