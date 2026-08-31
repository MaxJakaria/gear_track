import 'package:flutter/material.dart';

/// Stock Count Pill Badge Widget for POS Search Results
class PosStockPill extends StatelessWidget {
  final int totalStock;

  const PosStockPill({
    super.key,
    required this.totalStock,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isHighStock = totalStock > 5;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: isHighStock
            ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
            : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$totalStock',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isHighStock
              ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF166534))
              : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B)),
        ),
      ),
    );
  }
}
