import 'package:flutter/material.dart';

class StockStatusBadge extends StatelessWidget {
  final int totalStockCount;

  const StockStatusBadge({
    super.key,
    required this.totalStockCount,
  });

  Color _getStockColor() {
    if (totalStockCount <= 0) {
      return const Color(0xFFD32F2F);
    }
    return const Color(0xFF2E7D32);
  }

  String _getStockLabel() {
    if (totalStockCount <= 0) {
      return 'Out of Stock';
    }
    return '$totalStockCount in Stock';
  }


  @override
  Widget build(BuildContext context) {
    final stockColor = _getStockColor();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: stockColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: stockColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: stockColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            _getStockLabel(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: stockColor,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),

        ],
      ),
    );
  }
}
