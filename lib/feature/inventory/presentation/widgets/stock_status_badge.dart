import 'package:flutter/material.dart';

class StockStatusBadge extends StatelessWidget {
  final int totalStockCount;

  const StockStatusBadge({super.key, required this.totalStockCount});

  Color _getBadgeColor() {
    if (totalStockCount <= 0) {
      return const Color(0xFFD32F2F); // Solid Red
    }
    return const Color(0xFF1B5E20); // Solid Deep Emerald Green
  }

  String _getStockLabel() {
    if (totalStockCount <= 0) {
      return 'Out of Stock';
    }
    return '$totalStockCount in Stock';
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getBadgeColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.45),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            _getStockLabel(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
