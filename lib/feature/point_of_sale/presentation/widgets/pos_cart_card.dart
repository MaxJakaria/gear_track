import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/utils/currency_formatter.dart';
import 'package:gear_track/feature/point_of_sale/presentation/bloc/pos_bloc.dart';
import 'package:gear_track/feature/point_of_sale/presentation/widgets/pos_cart_empty_view.dart';
import 'package:gear_track/feature/point_of_sale/presentation/widgets/pos_cart_item_tile.dart';

/// Standalone "Sales Cart" Card Component showing items list and total amount
class PosCartCard extends StatelessWidget {
  const PosCartCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        final cartItems = state is PosLoaded ? state.cartItems : const [];
        final itemCount = state is PosLoaded ? state.totalItemCount : 0;
        final totalAmount = state is PosLoaded ? state.totalAmount : 0.0;
        final outOfStockCount = cartItems
            .where((i) => i.availableStock <= 0)
            .length;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Green Pill + Sales Cart Title + Item Count Badge
              _buildHeader(theme, itemCount, outOfStockCount: outOfStockCount),

              const SizedBox(height: 8),

              // Cart Items List / Empty View
              if (cartItems.isEmpty)
                const PosCartEmptyView()
              else ...[
                ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return PosCartItemTile(
                      key: ValueKey(item.id),
                      item: item,
                      onQuantityChanged: (newQty) {
                        context.read<PosBloc>().add(
                          UpdateCartQuantityEvent(
                            cartItemId: item.id,
                            quantity: newQty,
                          ),
                        );
                      },
                      onPriceChanged: (newPrice) {
                        context.read<PosBloc>().add(
                          UpdateCartPriceEvent(
                            cartItemId: item.id,
                            price: newPrice,
                          ),
                        );
                      },
                      onProductChanged: (selectedBatch) {
                        final parentDocId = selectedBatch.id.contains('/')
                            ? selectedBatch.id.split('/')[0]
                            : selectedBatch.id;
                        final batchId = selectedBatch.id.contains('/')
                            ? selectedBatch.id.split('/')[1]
                            : '';

                        context.read<PosBloc>().add(
                          UpdateCartProductEvent(
                            cartItemId: item.id,
                            productId: parentDocId,
                            batchId: batchId,
                            partNo: selectedBatch.partNo,
                            itemName: selectedBatch.itemName,
                            costCode: selectedBatch.costCode,
                            availableStock: selectedBatch.stockCount,
                          ),
                        );
                      },
                      removeItem: () {
                        context.read<PosBloc>().add(
                          RemoveCartItemEvent(item.id),
                        );
                      },
                    );
                  },
                ),

                // Total Amount Section
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'TOTAL AMOUNT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      totalAmount.toCurrency(),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    int itemCount, {
    int outOfStockCount = 0,
  }) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF00A859), // Green pill
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        // Cart Icon
        Icon(Icons.shopping_cart, color: theme.colorScheme.primary, size: 24),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Text(
            '$itemCount',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (outOfStockCount > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 13,
                  color: Color(0xFFEF4444),
                ),
                const SizedBox(width: 4),
                Text(
                  '$outOfStockCount out of stock',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
