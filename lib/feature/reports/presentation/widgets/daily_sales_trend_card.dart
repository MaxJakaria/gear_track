import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/daily_sales_point.dart';

class DailySalesTrendCard extends StatelessWidget {
  final List<DailySalesPoint> trendPoints;
  final String currencySymbol;

  const DailySalesTrendCard({
    super.key,
    required this.trendPoints,
    this.currencySymbol = '৳',
  });

  String _formatYAxisValue(double value) {
    if (value <= 0) return '${currencySymbol}0k';
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

    final int count = trendPoints.length;

    final double maxRevenue = trendPoints.isEmpty
        ? 1000
        : trendPoints.map((e) => e.revenue).reduce(math.max);

    final double maxY = maxRevenue <= 0 ? 1000 : maxRevenue * 1.25;

    final List<FlSpot> spots = [];
    for (int i = 0; i < count; i++) {
      spots.add(FlSpot(i.toDouble(), trendPoints[i].revenue));
    }

    final double chartContentWidth = math.max(320.0, count * 36.0);
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
                'Daily Sales Trend',
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
                  const SizedBox(width: 6),
                  Text(
                    'Revenue',
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
            child: trendPoints.isEmpty
                ? const Center(child: Text('No trend data available'))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. PINNED Y-Axis Column (Never scrolls!)
                      SizedBox(
                        width: 44,
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: maxY,
                            minX: 0,
                            maxX: 1,
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
                                    if (value == meta.max && maxRevenue <= 0) {
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
                            lineBarsData: [
                              LineChartBarData(
                                spots: const [FlSpot(0, 0)],
                                color: Colors.transparent,
                                dotData: const FlDotData(show: false),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 2. Horizontally Scrollable Chart Area
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true, // Auto-scroll to newest dates on right
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                            child: SizedBox(
                              width: chartContentWidth,
                              child: LineChart(
                                LineChartData(
                                  minY: 0,
                                  maxY: maxY,
                                  minX: -0.3,
                                  maxX: count > 1
                                      ? (count - 1 + 0.3)
                                      : 1.0,
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: yInterval,
                                    getDrawingHorizontalLine: (value) => FlLine(
                                      color: isDark
                                          ? Colors.white
                                              .withValues(alpha: 0.08)
                                          : Colors.black
                                              .withValues(alpha: 0.06),
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
                                        interval: 1,
                                        getTitlesWidget: (value, meta) {
                                          final int index = value.round();
                                          if (index < 0 || index >= count) {
                                            return const SizedBox.shrink();
                                          }
                                          if ((value - index).abs() > 0.15) {
                                            return const SizedBox.shrink();
                                          }

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                top: 6.0),
                                            child: Text(
                                              trendPoints[index].label,
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
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: spots,
                                      isCurved: true,
                                      preventCurveOverShooting: true,
                                      curveSmoothness: 0.20,
                                      color: const Color(0xFF6366F1),
                                      barWidth: 2.5,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter: (spot, percent, barData,
                                            index) {
                                          return FlDotCirclePainter(
                                            radius: 3.5,
                                            color: const Color(0xFF6366F1),
                                            strokeWidth: 1.5,
                                            strokeColor: Colors.white,
                                          );
                                        },
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            const Color(0xFF6366F1)
                                                .withValues(alpha: 0.25),
                                            const Color(0xFF6366F1)
                                                .withValues(alpha: 0.0),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                  lineTouchData: LineTouchData(
                                    touchTooltipData: LineTouchTooltipData(
                                      getTooltipItems: (touchedSpots) {
                                        return touchedSpots.map((spot) {
                                          final int idx = spot.x.round();
                                          final point =
                                              (idx >= 0 && idx < count)
                                                  ? trendPoints[idx]
                                                  : null;
                                          final tooltipDate = point != null
                                              ? DateFormat('MMM d')
                                                  .format(point.date)
                                              : '';
                                          return LineTooltipItem(
                                            '$tooltipDate\n$currencySymbol${spot.y.toInt()}',
                                            const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          );
                                        }).toList();
                                      },
                                    ),
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
