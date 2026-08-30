import 'package:equatable/equatable.dart';
import 'analytics_summary.dart';
import 'daily_sales_point.dart';
import 'monthly_profit_point.dart';
import 'report_period.dart';
import 'sales_record_detail.dart';

class AnalyticsReport extends Equatable {
  final ReportPeriod period;
  final AnalyticsSummary summary;
  final List<SalesRecordDetail> salesRecords;
  final List<DailySalesPoint> dailySalesTrend;
  final List<MonthlyProfitPoint> monthlyProfitTrend;
  final DateTime? startDate;
  final DateTime? endDate;

  const AnalyticsReport({
    required this.period,
    required this.summary,
    required this.salesRecords,
    required this.dailySalesTrend,
    required this.monthlyProfitTrend,
    this.startDate,
    this.endDate,
  });

  const AnalyticsReport.empty()
      : period = ReportPeriod.today,
        summary = const AnalyticsSummary.empty(),
        salesRecords = const [],
        dailySalesTrend = const [],
        monthlyProfitTrend = const [],
        startDate = null,
        endDate = null;

  @override
  List<Object?> get props => [
        period,
        summary,
        salesRecords,
        dailySalesTrend,
        monthlyProfitTrend,
        startDate,
        endDate,
      ];
}
