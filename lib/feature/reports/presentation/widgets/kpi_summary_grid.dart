import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/analytics_summary.dart';
import 'kpi_metric_card.dart';

class KpiSummaryGrid extends StatelessWidget {
  final AnalyticsSummary summary;
  final bool showInvestment;
  final String currencySymbol;

  const KpiSummaryGrid({
    super.key,
    required this.summary,
    this.showInvestment = true,
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
    return Column(
      children: [
        if (showInvestment) ...[
          // 1. Total Investment Card (on top, hidden when filter is applied)
          SizedBox(
            width: double.infinity,
            child: KpiMetricCard(
              label: 'Total Investment',
              value: _formatCurrency(summary.totalInvestment),
            ),
          ),
          const SizedBox(height: 12),
        ],

        Row(
          children: [
            // 2. Total Revenue Card
            Expanded(
              child: KpiMetricCard(
                label: 'Total Revenue',
                value: _formatCurrency(summary.totalSales),
              ),
            ),

            const SizedBox(width: 12),

            // 3. Total Profit Card
            Expanded(
              child: KpiMetricCard(
                label: 'Total Profit',
                value: _formatCurrency(summary.totalProfit),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
