import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gear_track/core/theme/app_colors.dart';
import '../../domain/entities/monthly_profit_point.dart';

class MonthlyProfitChartCard extends StatefulWidget {
  final List<MonthlyProfitPoint> monthlyData;
  final String currencySymbol;

  const MonthlyProfitChartCard({
    super.key,
    required this.monthlyData,
    this.currencySymbol = '৳',
  });

  @override
  State<MonthlyProfitChartCard> createState() => _MonthlyProfitChartCardState();
}

class _MonthlyProfitChartCardState extends State<MonthlyProfitChartCard> {
  // Zoom scale dynamically scales both X (width) and Y (height) for 2D scrolling
  double _zoomScale = 1.0;

  void _zoomIn() {
    setState(() {
      _zoomScale = (_zoomScale + 0.25).clamp(1.0, 2.25);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomScale = (_zoomScale - 0.25).clamp(1.0, 2.25);
    });
  }

  void _resetZoom() {
    setState(() {
      _zoomScale = 1.0;
    });
  }

  String _formatYAxisValue(double value) {
    if (value <= 0) return '0';
    if (value >= 1000000) {
      return '${widget.currencySymbol}${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${widget.currencySymbol}${(value / 1000).toStringAsFixed(0)}k';
    }
    return '${widget.currencySymbol}${value.toInt()}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final pillBg = isDark
        ? AppColors.surfaceContainerDark
        : AppColors.surfaceContainerLight;

    final int count = widget.monthlyData.length;

    double maxVal = 1000.0;
    for (final pt in widget.monthlyData) {
      maxVal = math.max(maxVal, math.max(pt.sales, pt.profit));
    }
    final double maxY = (maxVal <= 0 ? 1000.0 : maxVal * 1.25);

    // 2D Dimensions inside fixed 310px viewport (Reduced row gap for more visible rows & denser grid)
    final double columnSpacing =
        math.max(38.0, (280.0 / math.max(1, count))) * _zoomScale;
    final double rodWidth = (8.0 * math.min(1.4, _zoomScale)).clamp(5.0, 14.0);
    final double innerSpace = (2.5 * math.min(1.4, _zoomScale)).clamp(1.5, 5.0);
    final double chartContentWidth = math.max(320.0, count * columnSpacing);
    final double innerChartHeight = 310.0 * _zoomScale;
    final double yInterval = (maxY / 6).clamp(1.0, double.infinity);
    final int zoomPercent = (_zoomScale * 100).toInt();

    final List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < count; i++) {
      final point = widget.monthlyData[i];
      barGroups.add(
        BarChartGroupData(
          x: i,
          barsSpace: innerSpace,
          barRods: [
            // 1. Sales Bar (Deep Indigo at Top -> Light Indigo at Bottom)
            BarChartRodData(
              toY: math.max(0.0, point.sales),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF3730A3), // Deep Indigo (Top)
                  Color(0xFF6366F1), // Indigo (Middle)
                ],
              ),
              width: rodWidth,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            // 2. Profit Bar (Deep Emerald at Top -> Light Mint at Bottom)
            BarChartRodData(
              toY: math.max(0.0, point.profit),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF047857), // Deep Emerald (Top)
                  Color(0xFF10B981), // Emerald (Middle)
                ],
              ),
              width: rodWidth,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    final int displayYear = widget.monthlyData.isNotEmpty
        ? widget.monthlyData.first.monthDate.year
        : DateTime.now().year;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
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
          // Responsive Header: Title + Legend on left, Zoom Pill on right (Zero Overflow)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sales vs. Profit ($displayYear)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Legend Sub-Row
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF6366F1),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Sales',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Profit',
                          style: TextStyle(
                            fontSize: 11,
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
              ),
              const SizedBox(width: 8),

              // Zoom Control Pill
              Container(
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: _zoomOut,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.remove_rounded,
                          size: 15,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _resetZoom,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5.0,
                          vertical: 2.0,
                        ),
                        child: Text(
                          '$zoomPercent%',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: zoomPercent != 100
                                ? const Color(0xFF6366F1)
                                : (isDark
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF475569)),
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _zoomIn,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.add_rounded,
                          size: 15,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // STRICTLY FIXED HEIGHT (310px) Card with 2D Scrollable Viewport
          SizedBox(
            height: 310,
            child: widget.monthlyData.isEmpty
                ? const Center(child: Text('No monthly data available'))
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical, // Y-Axis Scroll
                    child: SizedBox(
                      height: innerChartHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Y-Axis Column
                          SizedBox(
                            width: 40,
                            child: BarChart(
                              BarChartData(
                                minY: 0,
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
                                      reservedSize: 22,
                                      getTitlesWidget: _emptyTitles,
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
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
                                            fontSize: 9.5,
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

                          // X-Axis Horizontally Scrollable Bar Chart (Starts from Jan on the left)
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                child: SizedBox(
                                  width: chartContentWidth,
                                  child: BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      minY: 0,
                                      maxY: maxY,
                                      barGroups: barGroups,
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: false,
                                        horizontalInterval: yInterval,
                                        getDrawingHorizontalLine: (value) =>
                                            FlLine(
                                              color: isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.08,
                                                    )
                                                  : Colors.black.withValues(
                                                      alpha: 0.06,
                                                    ),
                                              strokeWidth: 1,
                                              dashArray: [4, 4],
                                            ),
                                      ),
                                      titlesData: FlTitlesData(
                                        show: true,
                                        leftTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        rightTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        topTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 28,
                                            getTitlesWidget: (value, meta) {
                                              final int index = value.toInt();
                                              if (index < 0 || index >= count) {
                                                return const SizedBox.shrink();
                                              }
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 6.0,
                                                ),
                                                child: Text(
                                                  widget
                                                      .monthlyData[index]
                                                      .monthLabel,
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? const Color(
                                                            0xFF94A3B8,
                                                          )
                                                        : const Color(
                                                            0xFF64748B,
                                                          ),
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      barTouchData: BarTouchData(
                                        enabled: true,
                                        touchTooltipData: BarTouchTooltipData(
                                          fitInsideHorizontally: true,
                                          fitInsideVertically: true,
                                          getTooltipColor: (_) => isDark
                                              ? const Color(0xFF1E293B)
                                              : const Color(0xFF0F172A),
                                          getTooltipItem:
                                              (
                                                group,
                                                groupIndex,
                                                rod,
                                                rodIndex,
                                              ) {
                                                if (groupIndex < 0 ||
                                                    groupIndex >= count) {
                                                  return null;
                                                }
                                                final point = widget
                                                    .monthlyData[groupIndex];
                                                final isSales = rodIndex == 0;
                                                final label = isSales
                                                    ? 'Sales'
                                                    : 'Profit';
                                                final amount = isSales
                                                    ? point.sales
                                                    : point.profit;

                                                return BarTooltipItem(
                                                  '${point.monthLabel}\n',
                                                  const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12.5,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text:
                                                          '$label: ${widget.currencySymbol}${amount.toInt()}',
                                                      style: TextStyle(
                                                        color: isSales
                                                            ? const Color(
                                                                0xFF818CF8,
                                                              )
                                                            : const Color(
                                                                0xFF34D399,
                                                              ),
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 11.5,
                                                      ),
                                                    ),
                                                  ],
                                                );
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
