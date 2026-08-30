part of 'reports_bloc.dart';

abstract class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {}

class ReportsLoaded extends ReportsState {
  final AnalyticsReport report;
  final ReportPeriod activePeriod;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final bool isUpdating;

  const ReportsLoaded({
    required this.report,
    required this.activePeriod,
    this.customStartDate,
    this.customEndDate,
    this.isUpdating = false,
  });

  ReportsLoaded copyWith({
    AnalyticsReport? report,
    ReportPeriod? activePeriod,
    DateTime? customStartDate,
    DateTime? customEndDate,
    bool? isUpdating,
  }) {
    return ReportsLoaded(
      report: report ?? this.report,
      activePeriod: activePeriod ?? this.activePeriod,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }

  @override
  List<Object?> get props => [
        report,
        activePeriod,
        customStartDate,
        customEndDate,
        isUpdating,
      ];
}

class ReportsError extends ReportsState {
  final String message;

  const ReportsError(this.message);

  @override
  List<Object?> get props => [message];
}
