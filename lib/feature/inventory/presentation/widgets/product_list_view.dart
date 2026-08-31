import 'package:flutter/material.dart';
import 'package:gear_track/feature/inventory/domain/entities/grouped_product.dart';
import 'package:gear_track/feature/inventory/presentation/widgets/product_card.dart';
import 'package:gear_track/feature/inventory/presentation/widgets/quick_add_stock_sheet.dart';

/// Scrollable Product List View component
class ProductListView extends StatelessWidget {
  final List<GroupedProduct> products;
  final String? expandedCardKey;
  final ValueChanged<String?> onToggleExpand;
  final Future<void> Function() onRefresh;

  const ProductListView({
    super.key,
    required this.products,
    required this.expandedCardKey,
    required this.onToggleExpand,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final item = products[index];
          final isCardExpanded = expandedCardKey == item.itemName;

          return ProductCard(
            groupedProduct: item,
            cardIndex: index,
            isExpanded: isCardExpanded,
            onToggleExpand: () {
              onToggleExpand(isCardExpanded ? null : item.itemName);
            },
            onQuickAdd: () => QuickAddStockSheet.show(context, item),
          );
        },
      ),
    );
  }
}
