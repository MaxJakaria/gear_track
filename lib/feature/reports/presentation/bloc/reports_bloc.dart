import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/analytics_report.dart';
import '../../domain/entities/report_period.dart';
import '../../domain/usecases/get_analytics_report.dart';

part 'reports_event.dart';
part 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final GetAnalyticsReport getAnalyticsReport;
  ReportPeriod _currentPeriod = ReportPeriod.trends;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  ReportsBloc({required this.getAnalyticsReport}) : super(ReportsInitial()) {
    on<FetchReportsEvent>(_onFetchReports);
    on<SelectCustomDateRangeEvent>(_onSelectCustomDateRange);
    on<ClearDateFilterEvent>(_onClearDateFilter);
    on<RefreshReportsEvent>(_onRefreshReports);
  }

  Future<void> _onFetchReports(
    FetchReportsEvent event,
    Emitter<ReportsState> emit,
  ) async {
    _currentPeriod = event.period;
    _customStartDate = event.startDate;
    _customEndDate = event.endDate;

    if (state is ReportsLoaded) {
      emit((state as ReportsLoaded).copyWith(
        isUpdating: true,
        activePeriod: _currentPeriod,
        customStartDate: _customStartDate,
        customEndDate: _customEndDate,
      ));
    } else {
      emit(ReportsLoading());
    }

    final result = await getAnalyticsReport(
      _currentPeriod,
      startDate: _customStartDate,
      endDate: _customEndDate,
    );
    result.fold(
      (failure) => emit(ReportsError(failure.message)),
      (report) => emit(ReportsLoaded(
        report: report,
        activePeriod: _currentPeriod,
        customStartDate: _customStartDate,
        customEndDate: _customEndDate,
        isUpdating: false,
      )),
    );
  }

  Future<void> _onSelectCustomDateRange(
    SelectCustomDateRangeEvent event,
    Emitter<ReportsState> emit,
  ) async {
    _currentPeriod = ReportPeriod.custom;
    _customStartDate = event.startDate;
    _customEndDate = event.endDate;

    if (state is ReportsLoaded) {
      emit((state as ReportsLoaded).copyWith(
        isUpdating: true,
        activePeriod: _currentPeriod,
        customStartDate: _customStartDate,
        customEndDate: _customEndDate,
      ));
    } else {
      emit(ReportsLoading());
    }

    final result = await getAnalyticsReport(
      _currentPeriod,
      startDate: _customStartDate,
      endDate: _customEndDate,
    );
    result.fold(
      (failure) => emit(ReportsError(failure.message)),
      (report) => emit(ReportsLoaded(
        report: report,
        activePeriod: _currentPeriod,
        customStartDate: _customStartDate,
        customEndDate: _customEndDate,
        isUpdating: false,
      )),
    );
  }

  Future<void> _onClearDateFilter(
    ClearDateFilterEvent event,
    Emitter<ReportsState> emit,
  ) async {
    _currentPeriod = ReportPeriod.trends;
    _customStartDate = null;
    _customEndDate = null;

    if (state is ReportsLoaded) {
      emit((state as ReportsLoaded).copyWith(
        isUpdating: true,
        activePeriod: _currentPeriod,
        customStartDate: null,
        customEndDate: null,
      ));
    } else {
      emit(ReportsLoading());
    }

    final result = await getAnalyticsReport(
      _currentPeriod,
      startDate: null,
      endDate: null,
    );
    result.fold(
      (failure) => emit(ReportsError(failure.message)),
      (report) => emit(ReportsLoaded(
        report: report,
        activePeriod: _currentPeriod,
        customStartDate: null,
        customEndDate: null,
        isUpdating: false,
      )),
    );
  }

  Future<void> _onRefreshReports(
    RefreshReportsEvent event,
    Emitter<ReportsState> emit,
  ) async {
    final result = await getAnalyticsReport(
      _currentPeriod,
      startDate: _customStartDate,
      endDate: _customEndDate,
    );
    result.fold(
      (failure) => emit(ReportsError(failure.message)),
      (report) => emit(ReportsLoaded(
        report: report,
        activePeriod: _currentPeriod,
        customStartDate: _customStartDate,
        customEndDate: _customEndDate,
        isUpdating: false,
      )),
    );
  }
}
