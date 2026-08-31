import 'package:flutter/material.dart';
import 'package:gear_track/core/theme/app_colors.dart';
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

    final primaryColor = AppColors.primaryButton(context);

    return Row(
      children: [
        // 1. Total Revenue
        Expanded(
          child: KpiMetricCard(
            label: 'Total Revenue',
            value: _formatAmount(summary.totalSales),
            accentColor: primaryColor,
            icon: Icons.trending_up_rounded,
            subtitle: 'Gross sales',
          ),
        ),
        const SizedBox(width: 12),
        // 2. Total Profit
        Expanded(
          child: KpiMetricCard(
            label: 'Total Profit',
            value: _formatAmount(summary.totalProfit),
            accentColor: const Color(0xFF10B981), // Emerald
            icon: Icons.account_balance_wallet_outlined,
            subtitle: marginPercent > 0
                ? '${marginPercent.toStringAsFixed(1)}% margin'
                : 'Gross profit',
          ),
        ),
      ],
    );
  }
}
