import 'package:flutter/material.dart';
import 'package:gear_track/feature/inventory/domain/entities/grouped_product.dart';
import 'package:gear_track/feature/product_of_sales/presentation/widgets/pos_stock_pill.dart';

/// Single Product Search Result Tile Widget for POS Dropdown List
class PosSearchResultTile extends StatelessWidget {
  final GroupedProduct grouped;
  final VoidCallback onTap;

  const PosSearchResultTile({
    super.key,
    required this.grouped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    grouped.itemName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    grouped.partNo,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF818CF8)
                          : const Color(0xFF6366F1),
                    ),
                  ),
                ],
              ),
            ),
            PosStockPill(totalStock: grouped.totalStockCount),
          ],
        ),
      ),
    );
  }
}
