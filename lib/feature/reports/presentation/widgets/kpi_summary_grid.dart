import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: currencySymbol,
      decimalDigits: amount % 1 == 0 ? 0 : 1,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 1. Total Revenue Card
        Expanded(
          child: KpiMetricCard(
            label: 'Total Revenue',
            value: _formatCurrency(summary.totalSales),
          ),
        ),

        const SizedBox(width: 12),

        // 2. Total Profit Card
        Expanded(
          child: KpiMetricCard(
            label: 'Total Profit',
            value: _formatCurrency(summary.totalProfit),
          ),
        ),
      ],
    );
  }
}
