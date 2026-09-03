import 'package:flutter/material.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';

/// Presentation widget displaying contextual empty states for Inventory page (SRP)
class InventoryEmptyView extends StatelessWidget {
  final bool hasSearch;
  final StockFilter activeFilter;
  final VoidCallback onClearSearch;
  final VoidCallback onResetFilter;
  final Future<void> Function()? onRefresh;

  const InventoryEmptyView({
    super.key,
    required this.hasSearch,
    required this.activeFilter,
    required this.onClearSearch,
    required this.onResetFilter,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData iconData = Icons.inventory_2_outlined;
    String title = 'No products in inventory yet';
    String subtitle =
        'Tap the "Add Product" button below to add your first product.';
    Widget? actionButton;

    if (hasSearch) {
      iconData = Icons.search_off_rounded;
      title = 'No matching products found';
      subtitle = 'Try searching with a different keyword or reset the filter.';
      actionButton = TextButton.icon(
        onPressed: onClearSearch,
        icon: const Icon(Icons.clear_rounded, size: 16),
        label: const Text('Clear Search'),
      );
    } else if (activeFilter == StockFilter.lowStockProduct) {
      iconData = Icons.verified_outlined;
      title = 'No Low Stock Products (Product Level)';
      subtitle = 'Great! None of your products have total stock of 1–5 units.';
      actionButton = TextButton.icon(
        onPressed: onResetFilter,
        icon: const Icon(Icons.grid_view_rounded, size: 16),
        label: const Text('View All Products'),
      );
    } else if (activeFilter == StockFilter.lowStockBatch) {
      iconData = Icons.verified_outlined;
      title = 'No Low Stock Products (Batch Level)';
      subtitle = 'Great! None of your products have low-stock batches.';
      actionButton = TextButton.icon(
        onPressed: onResetFilter,
        icon: const Icon(Icons.grid_view_rounded, size: 16),
        label: const Text('View All Products'),
      );
    } else if (activeFilter == StockFilter.outOfStockProduct) {
      iconData = Icons.check_circle_outline_rounded;
      title = 'No Out of Stock Products (Product Level)';
      subtitle = 'Awesome! None of your products are completely out of stock.';
      actionButton = TextButton.icon(
        onPressed: onResetFilter,
        icon: const Icon(Icons.grid_view_rounded, size: 16),
        label: const Text('View All Products'),
      );
    } else if (activeFilter == StockFilter.outOfStockBatch) {
      iconData = Icons.check_circle_outline_rounded;
      title = 'No Out of Stock Products (Batch Level)';
      subtitle = 'Awesome! None of your products have out-of-stock batches.';
      actionButton = TextButton.icon(
        onPressed: onResetFilter,
        icon: const Icon(Icons.grid_view_rounded, size: 16),
        label: const Text('View All Products'),
      );
    } else if (activeFilter == StockFilter.inStock) {
      iconData = Icons.remove_shopping_cart_outlined;
      title = 'No In-Stock Products';
      subtitle = 'There are currently no products with available stock.';
      actionButton = TextButton.icon(
        onPressed: onResetFilter,
        icon: const Icon(Icons.grid_view_rounded, size: 16),
        label: const Text('View All Products'),
      );
    }

    final content = Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionButton != null) ...[
              const SizedBox(height: 14),
              actionButton,
            ],
          ],
        ),
      ),
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: content,
            ),
          ],
        ),
      );
    }

    return content;
  }
}
