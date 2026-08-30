import '../../domain/entities/analytics_summary.dart';

class AnalyticsSummaryModel extends AnalyticsSummary {
  const AnalyticsSummaryModel({
    required super.totalSales,
    required super.totalProfit,
    required super.itemsSold,
    required super.lowStockAlerts,
  });

  factory AnalyticsSummaryModel.fromMap(Map<String, dynamic> map) {
    return AnalyticsSummaryModel(
      totalSales: (map['totalSales'] as num?)?.toDouble() ?? 0.0,
      totalProfit: (map['totalProfit'] as num?)?.toDouble() ?? 0.0,
      itemsSold: (map['itemsSold'] as num?)?.toInt() ?? 0,
      lowStockAlerts: (map['lowStockAlerts'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalSales': totalSales,
      'totalProfit': totalProfit,
      'itemsSold': itemsSold,
      'lowStockAlerts': lowStockAlerts,
    };
  }

  factory AnalyticsSummaryModel.fromEntity(AnalyticsSummary entity) {
    return AnalyticsSummaryModel(
      totalSales: entity.totalSales,
      totalProfit: entity.totalProfit,
      itemsSold: entity.itemsSold,
      lowStockAlerts: entity.lowStockAlerts,
    );
  }
}
