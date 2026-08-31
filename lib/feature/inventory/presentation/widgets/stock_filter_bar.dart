import 'package:flutter/material.dart';
import 'package:gear_track/core/theme/app_colors.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';

/// Unified Linear Gradient Stock Filter Bar
class StockFilterBar extends StatelessWidget {
  final StockFilter activeFilter;
  final int totalCount;
  final int lowStockCount;
  final int outOfStockCount;
  final int inStockCount;
  final ValueChanged<StockFilter> onFilterSelected;

  const StockFilterBar({
    super.key,
    required this.activeFilter,
    required this.totalCount,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.inStockCount,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _UnifiedGradientFilterChip(
              label: 'All',
              count: totalCount,
              isSelected: activeFilter == StockFilter.all,
              isDark: isDark,
              onTap: () => onFilterSelected(StockFilter.all),
            ),
            const SizedBox(width: 6),
            _UnifiedGradientFilterChip(
              label: 'Low Stock',
              count: lowStockCount,
              statusColor: const Color(0xFFF59E0B), // Amber dot
              showIndicator: lowStockCount > 0,
              isSelected: activeFilter == StockFilter.lowStock,
              isDark: isDark,
              onTap: () => onFilterSelected(StockFilter.lowStock),
            ),
            const SizedBox(width: 6),
            _UnifiedGradientFilterChip(
              label: 'Out of Stock',
              count: outOfStockCount,
              statusColor: const Color(0xFFEF4444), // Red dot
              showIndicator: outOfStockCount > 0,
              isSelected: activeFilter == StockFilter.outOfStock,
              isDark: isDark,
              onTap: () => onFilterSelected(StockFilter.outOfStock),
            ),
            const SizedBox(width: 6),
            _UnifiedGradientFilterChip(
              label: 'In Stock',
              count: inStockCount,
              isSelected: activeFilter == StockFilter.inStock,
              isDark: isDark,
              onTap: () => onFilterSelected(StockFilter.inStock),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnifiedGradientFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color? statusColor;
  final bool showIndicator;
  final bool isDark;
  final VoidCallback onTap;

  const _UnifiedGradientFilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    this.statusColor,
    this.showIndicator = false,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = AppColors.primaryGradient(context);
    final primaryColor = AppColors.primaryButton(context);

    final unselectedBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);

    final selectedText = Colors.white;
    final unselectedText = isDark
        ? Colors.white.withValues(alpha: 0.70)
        : const Color(0xFF475569);

    final selectedCountColor = Colors.white.withValues(alpha: 0.85);
    final unselectedCountColor = isDark
        ? Colors.white.withValues(alpha: 0.40)
        : const Color(0xFF94A3B8);

    final border = isSelected
        ? Border.all(
            color: primaryColor,
            width: 1,
          )
        : Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.08),
            width: 1,
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? null : unselectedBg,
            gradient: isSelected ? gradient : null,
            borderRadius: BorderRadius.circular(20),
            border: border,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.28),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status indicator dot
              if (showIndicator && statusColor != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],

              // Label
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? selectedText : unselectedText,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 5),

              // Count Number
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? selectedCountColor : unselectedCountColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
