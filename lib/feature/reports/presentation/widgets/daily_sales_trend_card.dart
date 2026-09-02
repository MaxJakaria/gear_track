import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gear_track/core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/daily_sales_point.dart';

class DailySalesTrendCard extends StatefulWidget {
  final List<DailySalesPoint> trendPoints;
  final String currencySymbol;

  const DailySalesTrendCard({
    super.key,
    required this.trendPoints,
    this.currencySymbol = '৳',
  });

  @override
  State<DailySalesTrendCard> createState() => _DailySalesTrendCardState();
}

class _DailySalesTrendCardState extends State<DailySalesTrendCard> {
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
    if (value <= 0) return '${widget.currencySymbol}0';
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

    final int count = widget.trendPoints.length;
    final double maxRevenue = widget.trendPoints.isEmpty
        ? 1000
        : widget.trendPoints.map((e) => e.revenue).reduce(math.max);
    final double maxY = maxRevenue <= 0 ? 1000 : maxRevenue * 1.25;

    final List<FlSpot> spots = [];
    for (int i = 0; i < count; i++) {
      spots.add(FlSpot(i.toDouble(), widget.trendPoints[i].revenue));
    }

    // 2D Dimensions inside fixed 310px viewport (Reduced row gap for more visible rows & denser grid)
    final double pointSpacing = 32.0 * _zoomScale;
    final double chartContentWidth = math.max(320.0, count * pointSpacing);
    final double innerChartHeight = 310.0 * _zoomScale;
    final double yInterval = (maxY / 6).clamp(1.0, double.infinity);
    final int zoomPercent = (_zoomScale * 100).toInt();

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
          // Header: Title, Legend & Zoom Controls (Days chips removed)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Daily Sales Trend',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),

              // Legend & Zoom Control Pill
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
                    'Revenue',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Zoom Control Pill
                  Container(
                    decoration: BoxDecoration(
                      color: pillBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
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
            ],
          ),

          const SizedBox(height: 10),

          // STRICTLY FIXED HEIGHT (310px) Card with 2D Scrollable Viewport
          SizedBox(
            height: 310,
            child: widget.trendPoints.isEmpty
                ? const Center(child: Text('No trend data available'))
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
                                        if (value == meta.max &&
                                            maxRevenue <= 0) {
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

                          // X-Axis Horizontally Scrollable Timeline
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal, // X-Axis Scroll
                              reverse: true,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                child: SizedBox(
                                  width: chartContentWidth,
                                  child: LineChart(
                                    LineChartData(
                                      minY: 0,
                                      maxY: maxY,
                                      minX: -0.3,
                                      maxX: count > 1 ? (count - 1 + 0.3) : 1.0,
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
                                            reservedSize: 26,
                                            interval: 1,
                                            getTitlesWidget: (value, meta) {
                                              final int index = value.round();
                                              if (index < 0 || index >= count) {
                                                return const SizedBox.shrink();
                                              }
                                              if ((value - index).abs() >
                                                  0.15) {
                                                return const SizedBox.shrink();
                                              }

                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 6.0,
                                                ),
                                                child: Text(
                                                  widget
                                                      .trendPoints[index]
                                                      .label,
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? const Color(
                                                            0xFF94A3B8,
                                                          )
                                                        : const Color(
                                                            0xFF64748B,
                                                          ),
                                                    fontSize: 10.5,
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
                                          barWidth:
                                              2.5 * math.min(1.4, _zoomScale),
                                          isStrokeCapRound: true,
                                          dotData: FlDotData(
                                            show: true,
                                            getDotPainter:
                                                (
                                                  spot,
                                                  percent,
                                                  barData,
                                                  index,
                                                ) {
                                                  return FlDotCirclePainter(
                                                    radius:
                                                        3.5 *
                                                        math.min(
                                                          1.3,
                                                          _zoomScale,
                                                        ),
                                                    color: const Color(
                                                      0xFF6366F1,
                                                    ),
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
                                                const Color(
                                                  0xFF6366F1,
                                                ).withValues(alpha: 0.25),
                                                const Color(
                                                  0xFF6366F1,
                                                ).withValues(alpha: 0.0),
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
                                                  ? widget.trendPoints[idx]
                                                  : null;
                                              final tooltipDate = point != null
                                                  ? DateFormat(
                                                      'MMM d',
                                                    ).format(point.date)
                                                  : '';
                                              return LineTooltipItem(
                                                '$tooltipDate\n${widget.currencySymbol}${spot.y.toInt()}',
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
