import 'package:flutter/material.dart';
import 'package:gear_track/core/theme/app_colors.dart';
import '../../domain/entities/daily_sales_point.dart';
import '../../domain/entities/monthly_profit_point.dart';
import 'daily_sales_trend_card.dart';
import 'monthly_profit_chart_card.dart';

enum ReportChartTab { daily, monthly }

/// Interactive Performance Trends Section that contains Daily and Monthly toggle buttons
/// styled consistently with the project's primary gradient and color palette,
/// seamlessly switching between DailySalesTrendCard and MonthlyProfitChartCard.
class PerformanceTrendsSection extends StatefulWidget {
  final List<DailySalesPoint> dailySalesTrend;
  final List<MonthlyProfitPoint> monthlyProfitTrend;
  final String currencySymbol;

  const PerformanceTrendsSection({
    super.key,
    required this.dailySalesTrend,
    required this.monthlyProfitTrend,
    this.currencySymbol = '৳',
  });

  @override
  State<PerformanceTrendsSection> createState() =>
      _PerformanceTrendsSectionState();
}

class _PerformanceTrendsSectionState extends State<PerformanceTrendsSection> {
  ReportChartTab _selectedChartTab = ReportChartTab.daily;

  Widget _buildChartTabButton({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final gradient = AppColors.primaryGradient(context);
    final primaryColor = AppColors.primaryButton(context);

    final unselectedBg = isDark
        ? AppColors.surfaceContainerDark
        : AppColors.surfaceContainerLight;
    final unselectedBorder = isDark
        ? AppColors.borderDark
        : AppColors.borderLight;
    final unselectedTextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF475569);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: isSelected ? gradient : null,
            color: isSelected ? null : unselectedBg,
            border: isSelected
                ? Border.all(color: primaryColor)
                : Border.all(color: unselectedBorder),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? AppColors.buttonForeground
                    : unselectedTextColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartTypeSelector(BuildContext context, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildChartTabButton(
          context: context,
          label: 'Daily',
          isSelected: _selectedChartTab == ReportChartTab.daily,
          onTap: () {
            if (_selectedChartTab != ReportChartTab.daily) {
              setState(() {
                _selectedChartTab = ReportChartTab.daily;
              });
            }
          },
          isDark: isDark,
        ),
        const SizedBox(width: 10),
        _buildChartTabButton(
          context: context,
          label: 'Monthly',
          isSelected: _selectedChartTab == ReportChartTab.monthly,
          onTap: () {
            if (_selectedChartTab != ReportChartTab.monthly) {
              setState(() {
                _selectedChartTab = ReportChartTab.monthly;
              });
            }
          },
          isDark: isDark,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChartTypeSelector(context, isDark),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _selectedChartTab == ReportChartTab.daily
              ? DailySalesTrendCard(
                  key: const ValueKey('daily_sales_chart'),
                  trendPoints: widget.dailySalesTrend,
                  currencySymbol: widget.currencySymbol,
                )
              : MonthlyProfitChartCard(
                  key: const ValueKey('monthly_profit_chart'),
                  monthlyData: widget.monthlyProfitTrend,
                  currencySymbol: widget.currencySymbol,
                ),
        ),
      ],
    );
  }
}
