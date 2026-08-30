import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/monthly_profit_point.dart';

class MonthlyProfitChartCard extends StatelessWidget {
  final List<MonthlyProfitPoint> monthlyData;
  final String currencySymbol;

  const MonthlyProfitChartCard({
    super.key,
    required this.monthlyData,
    this.currencySymbol = '৳',
  });

  String _formatYAxisValue(double value) {
    if (value <= 0) return '0';
    if (value >= 1000) {
      return '$currencySymbol${(value / 1000).toStringAsFixed(0)}k';
    }
    return '$currencySymbol${value.toInt()}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark
        ? theme.colorScheme.surfaceContainerHigh
        : Colors.white;

    double maxVal = 1000.0;
    for (final pt in monthlyData) {
      maxVal = math.max(maxVal, math.max(pt.sales, pt.profit));
    }
    final double maxY = (maxVal <= 0 ? 1000.0 : maxVal * 1.25);

    final List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < monthlyData.length; i++) {
      final point = monthlyData[i];
      barGroups.add(
        BarChartGroupData(
          x: i,
          barsSpace: 4,
          barRods: [
            // 1. Sales Bar (Indigo)
            BarChartRodData(
              toY: point.sales,
              color: const Color(0xFF6366F1),
              width: 12,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            // 2. Profit Bar (Emerald)
            BarChartRodData(
              toY: point.profit,
              color: const Color(0xFF10B981),
              width: 12,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    final double chartContentWidth = math.max(300.0, monthlyData.length * 52.0);
    final double yInterval = (maxY / 4).clamp(1.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clean Header Row: Title & Legend only
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Monthly Sales vs. Profit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              // Legend
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6366F1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Sales',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Profit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Pinned Y-Axis + Scrollable Chart Body
          SizedBox(
            height: 210,
            child: monthlyData.isEmpty
                ? const Center(child: Text('No monthly data available'))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. PINNED Y-Axis Column (Never scrolls!)
                      SizedBox(
                        width: 44,
                        child: BarChart(
                          BarChartData(
                            maxY: maxY,
                            barGroups: const [],
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: const AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 26,
                                  getTitlesWidget: _emptyTitles,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 44,
                                  interval: yInterval,
                                  getTitlesWidget: (value, meta) {
                                    if (value == meta.max && maxVal <= 0) {
                                      return const SizedBox.shrink();
                                    }
                                    return Text(
                                      _formatYAxisValue(value),
                                      style: TextStyle(
                                        color: isDark
                                            ? const Color(0xFF64748B)
                                            : const Color(0xFF94A3B8),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 2. Horizontally Scrollable Bar Chart Area
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true, // Auto-scroll to current month on right
                          child: SizedBox(
                            width: chartContentWidth,
                            child: BarChart(
                              BarChartData(
                                maxY: maxY,
                                barGroups: barGroups,
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: yInterval,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.06),
                                    strokeWidth: 1,
                                    dashArray: [4, 4],
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: false), // Hidden on scrolling body
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 26,
                                      getTitlesWidget: (value, meta) {
                                        final int index = value.toInt();
                                        if (index < 0 ||
                                            index >= monthlyData.length) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 6.0),
                                          child: Text(
                                            monthlyData[index].monthLabel,
                                            style: TextStyle(
                                              color: isDark
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF64748B),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                barTouchData: BarTouchData(
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipItem:
                                        (group, groupIndex, rod, rodIndex) {
                                      final point = monthlyData[groupIndex];
                                      final isSales = rodIndex == 0;
                                      final label =
                                          isSales ? 'Sales' : 'Profit';
                                      final amount = isSales
                                          ? point.sales
                                          : point.profit;
                                      return BarTooltipItem(
                                        '${point.monthLabel}\n$label: $currencySymbol${amount.toInt()}',
                                        const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  static Widget _emptyTitles(double value, TitleMeta meta) {
    return const SizedBox.shrink();
  }
}
