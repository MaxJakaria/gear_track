import 'package:equatable/equatable.dart';

class AnalyticsSummary extends Equatable {
  final double totalSales;
  final double totalProfit;
  final int itemsSold;
  final int lowStockAlerts;

  const AnalyticsSummary({
    required this.totalSales,
    required this.totalProfit,
    required this.itemsSold,
    required this.lowStockAlerts,
  });

  const AnalyticsSummary.empty()
      : totalSales = 0.0,
        totalProfit = 0.0,
        itemsSold = 0,
        lowStockAlerts = 0;

  @override
  List<Object?> get props => [
        totalSales,
        totalProfit,
        itemsSold,
        lowStockAlerts,
      ];
}
