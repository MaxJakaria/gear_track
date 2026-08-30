import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/analytics_report.dart';
import '../../domain/entities/report_period.dart';
import 'analytics_summary_model.dart';
import 'daily_sales_point_model.dart';
import 'monthly_profit_point_model.dart';
import 'sales_record_detail_model.dart';

class AnalyticsReportModel extends AnalyticsReport {
  const AnalyticsReportModel({
    required super.period,
    required super.summary,
    required super.salesRecords,
    required super.dailySalesTrend,
    required super.monthlyProfitTrend,
    super.startDate,
    super.endDate,
  });

  factory AnalyticsReportModel.fromMap(Map<String, dynamic> map) {
    final periodString = map['period'] as String? ?? 'today';
    final period = ReportPeriod.values.firstWhere(
      (e) => e.name == periodString,
      orElse: () => ReportPeriod.today,
    );

    return AnalyticsReportModel(
      period: period,
      startDate: (map['startDate'] is Timestamp)
          ? (map['startDate'] as Timestamp).toDate()
          : (map['startDate'] != null
              ? DateTime.tryParse(map['startDate'].toString())
              : null),
      endDate: (map['endDate'] is Timestamp)
          ? (map['endDate'] as Timestamp).toDate()
          : (map['endDate'] != null
              ? DateTime.tryParse(map['endDate'].toString())
              : null),
      summary: map['summary'] != null
          ? AnalyticsSummaryModel.fromMap(
              Map<String, dynamic>.from(map['summary']),
            )
          : const AnalyticsSummaryModel(
              totalSales: 0,
              totalProfit: 0,
              itemsSold: 0,
              lowStockAlerts: 0,
            ),
      salesRecords: (map['salesRecords'] as List<dynamic>?)
              ?.map(
                (e) =>
                    SalesRecordDetailModel.fromMap(Map<String, dynamic>.from(e)),
              )
              .toList() ??
          [],
      dailySalesTrend: (map['dailySalesTrend'] as List<dynamic>?)
              ?.map(
                (e) =>
                    DailySalesPointModel.fromMap(Map<String, dynamic>.from(e)),
              )
              .toList() ??
          [],
      monthlyProfitTrend: (map['monthlyProfitTrend'] as List<dynamic>?)
              ?.map(
                (e) => MonthlyProfitPointModel.fromMap(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'period': period.name,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'summary': AnalyticsSummaryModel.fromEntity(summary).toMap(),
      'salesRecords': salesRecords
          .map((e) => SalesRecordDetailModel.fromEntity(e).toMap())
          .toList(),
      'dailySalesTrend': dailySalesTrend
          .map((e) => DailySalesPointModel.fromEntity(e).toMap())
          .toList(),
      'monthlyProfitTrend': monthlyProfitTrend
          .map((e) => MonthlyProfitPointModel.fromEntity(e).toMap())
          .toList(),
    };
  }

  factory AnalyticsReportModel.fromEntity(AnalyticsReport entity) {
    return AnalyticsReportModel(
      period: entity.period,
      summary: entity.summary,
      salesRecords: entity.salesRecords,
      dailySalesTrend: entity.dailySalesTrend,
      monthlyProfitTrend: entity.monthlyProfitTrend,
      startDate: entity.startDate,
      endDate: entity.endDate,
    );
  }
}
