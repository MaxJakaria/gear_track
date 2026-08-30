part of 'reports_bloc.dart';

abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => [];
}

class FetchReportsEvent extends ReportsEvent {
  final ReportPeriod period;
  final DateTime? startDate;
  final DateTime? endDate;

  const FetchReportsEvent({
    this.period = ReportPeriod.trends,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [period, startDate, endDate];
}

class SelectCustomDateRangeEvent extends ReportsEvent {
  final DateTime startDate;
  final DateTime endDate;

  const SelectCustomDateRangeEvent({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

class ClearDateFilterEvent extends ReportsEvent {
  const ClearDateFilterEvent();
}

class RefreshReportsEvent extends ReportsEvent {
  const RefreshReportsEvent();
}
