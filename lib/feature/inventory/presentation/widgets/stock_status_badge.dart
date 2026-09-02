import 'package:flutter/material.dart';

/// Clean Stock Status Indicator for Product Cards (No Background)
/// - Normal (> 5): Green dot + white count
/// - Low stock (1-5 or batch alert): Amber dot + white count
/// - Out of stock (<= 0): Red alert icon
class StockStatusBadge extends StatelessWidget {
  final int totalStockCount;
  final bool hasOutOfStockBatch;
  final bool hasLowStockBatch;

  const StockStatusBadge({
    super.key,
    required this.totalStockCount,
    this.hasOutOfStockBatch = false,
    this.hasLowStockBatch = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOutOfStock = totalStockCount <= 0;
    final bool isLowStock = !isOutOfStock &&
        (hasLowStockBatch ||
            hasOutOfStockBatch ||
            (totalStockCount > 0 && totalStockCount <= 5));

    // 1. Out of Stock: Just Red Alert Icon
    if (isOutOfStock) {
      return const Icon(
        Icons.warning_rounded,
        size: 16,
        color: Color(0xFFEF4444),
      );
    }

    // 2. Low Stock (1 to 5 or alert batch): Amber Dot + White Count
    if (isLowStock) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFFFBBF24), // Bright Amber Dot
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$totalStockCount',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
          ),
        ],
      );
    }

    // 3. Normal (> 5): Green Dot + White Count
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Color(0xFF4ADE80), // Bright Green Dot
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '$totalStockCount',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
