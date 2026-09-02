import 'package:flutter/material.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';

/// Clean and containerless Active Filter Banner shown when a filter is applied
class ActiveFilterBanner extends StatelessWidget {
  final StockFilter activeFilter;
  final int count;
  final VoidCallback onClearFilter;
  final VoidCallback onOpenFilterSidebar;
  final VoidCallback? onClearAll;

  const ActiveFilterBanner({
    super.key,
    required this.activeFilter,
    required this.count,
    required this.onClearFilter,
    required this.onOpenFilterSidebar,
    this.onClearAll,
  });

  String get _filterTitle {
    return switch (activeFilter) {
      StockFilter.all => 'All Products',
      StockFilter.inStock => 'In Stock',
      StockFilter.lowStockProduct => 'Low Stock (Product)',
      StockFilter.lowStockBatch => 'Low Stock (Batch)',
      StockFilter.outOfStockProduct => 'Out of Stock (Product)',
      StockFilter.outOfStockBatch => 'Out of Stock (Batch)',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (activeFilter == StockFilter.all) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Functional Filter Icon (taps to open filter sidebar)
          GestureDetector(
            onTap: onOpenFilterSidebar,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(right: 8, top: 2, bottom: 2),
              child: Icon(
                Icons.tune_rounded,
                size: 20,
                color: isDark
                    ? const Color(0xFF818CF8)
                    : const Color(0xFF4F46E5),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onOpenFilterSidebar,
              behavior: HitTestBehavior.opaque,
              child: Text(
                '$_filterTitle • $count',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Clear All Button (without icon, pure text)
          if (onClearAll != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClearAll,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          // Reset Filter Dismiss Button
          GestureDetector(
            onTap: onClearFilter,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 17,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
