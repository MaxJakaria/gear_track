import 'package:flutter/material.dart';
import '../../domain/entities/analytics_summary.dart';
import 'kpi_metric_card.dart';

class KpiSummaryGrid extends StatelessWidget {
  final AnalyticsSummary summary;
  final String currencySymbol;

  const KpiSummaryGrid({
    super.key,
    required this.summary,
    this.currencySymbol = '৳',
  });

  String _formatAmount(double amount) {
    if (amount % 1 == 0) {
      return '$currencySymbol${amount.toInt()}';
    }
    return '$currencySymbol${amount.toStringAsFixed(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final double marginPercent = summary.totalSales > 0
        ? (summary.totalProfit / summary.totalSales) * 100
        : 0.0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        // 1. Total Sales
        KpiMetricCard(
          label: 'Total Revenue',
          value: _formatAmount(summary.totalSales),
          accentColor: const Color(0xFF4F46E5), // Indigo
          icon: Icons.trending_up_rounded,
          subtitle: 'Gross sales',
        ),
        // 2. Total Profit
        KpiMetricCard(
          label: 'Total Profit',
          value: _formatAmount(summary.totalProfit),
          accentColor: const Color(0xFF059669), // Emerald
          icon: Icons.account_balance_wallet_outlined,
          subtitle: marginPercent > 0
              ? '${marginPercent.toStringAsFixed(1)}% margin'
              : 'Gross profit',
        ),
        // 3. Items Sold
        KpiMetricCard(
          label: 'Units Sold',
          value: '${summary.itemsSold}',
          accentColor: const Color(0xFFD97706), // Amber
          icon: Icons.shopping_bag_outlined,
          subtitle: 'Total items',
        ),
        // 4. Low Stock Alerts
        KpiMetricCard(
          label: 'Low Stock',
          value: '${summary.lowStockAlerts}',
          accentColor: const Color(0xFFDC2626), // Crimson Red
          icon: Icons.warning_amber_rounded,
          subtitle: summary.lowStockAlerts > 0
              ? 'Needs restock'
              : 'Stock healthy',
        ),
      ],
    );
  }
}
