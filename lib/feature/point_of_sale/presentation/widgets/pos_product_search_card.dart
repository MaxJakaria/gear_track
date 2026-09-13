import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/feature/inventory/domain/entities/product.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:gear_track/feature/point_of_sale/domain/entities/cart_item.dart';
import 'package:gear_track/feature/point_of_sale/presentation/bloc/pos_bloc.dart';
import 'package:gear_track/feature/point_of_sale/presentation/widgets/pos_stock_pill.dart';

/// Sleek Minimal Pinned Search Bar
class PosProductSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String hintText;

  const PosProductSearchBar({
    super.key,
    required this.controller,
    this.focusNode,
    required this.onChanged,
    required this.onClear,
    this.hintText = 'Search by part no, product name, or model...',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.search,
        autocorrect: false,
        enableSuggestions: false,
        onChanged: onChanged,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
            fontSize: 12.5,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 38,
            minHeight: 20,
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 38,
            minHeight: 20,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onClear,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(
                      Icons.clear_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : null,
          filled: true,
          fillColor: isDark
              ? theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                )
              : Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

/// Full Screen Search Results View
class PosProductSearchResults extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<Product> onProductSelected;

  const PosProductSearchResults({
    super.key,
    required this.searchQuery,
    required this.onProductSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is InventoryLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is InventoryLoaded) {
          final allProducts = state.products;
          final q = searchQuery.trim().toLowerCase();

          final filteredBatches = q.isEmpty
              ? <Product>[]
              : allProducts
                    .where((p) {
                      final nameMatch = p.itemName.toLowerCase().contains(q);
                      final modelMatch = p.model.toLowerCase().contains(q);
                      final partMatch = p.partNo.toLowerCase().contains(q);

                      return nameMatch || modelMatch || partMatch;
                    })
                    .take(12)
                    .toList();

          if (q.isNotEmpty && filteredBatches.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No matching products found',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try searching with a different name, part number, or model',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (filteredBatches.isEmpty) {
            return const SizedBox.shrink();
          }

          return BlocBuilder<PosBloc, PosState>(
            builder: (context, posState) {
              final currentCart = posState is PosLoaded
                  ? posState.cartItems
                  : const <CartItem>[];

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: filteredBatches.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.4,
                  ),
                ),
                itemBuilder: (context, index) {
                  final productBatch = filteredBatches[index];
                  final parentDocId = productBatch.id.contains('/')
                      ? productBatch.id.split('/')[0]
                      : productBatch.id;
                  final batchId = productBatch.id.contains('/')
                      ? productBatch.id.split('/')[1]
                      : '';
                  final isInCart = currentCart.any(
                    (item) =>
                        item.productId == parentDocId &&
                        item.batchId == batchId,
                  );

                  return _PosDirectSearchResultTile(
                    product: productBatch,
                    isInCart: isInCart,
                    onTap: () {
                      if (productBatch.stockCount <= 0) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${productBatch.itemName} (${productBatch.partNo.isNotEmpty ? productBatch.partNo : 'Selected batch'}) is Out of Stock!',
                            ),
                            backgroundColor: const Color(0xFFDC2626),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      if (isInCart) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    productBatch.partNo.isNotEmpty
                                        ? '${productBatch.itemName} (PN: ${productBatch.partNo}) is already in the cart!'
                                        : '${productBatch.itemName} is already in the cart!',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFFD97706),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      onProductSelected(productBatch);
                    },
                  );
                },
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

/// Single Batch Search Result Tile - Direct 1-Click Add to Cart
class _PosDirectSearchResultTile extends StatelessWidget {
  final Product product;
  final bool isInCart;
  final VoidCallback onTap;

  const _PosDirectSearchResultTile({
    required this.product,
    this.isInCart = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOutOfStock = product.stockCount <= 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: isOutOfStock ? 0.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.itemName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isOutOfStock
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                            : theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (product.partNo.isNotEmpty) ...[
                          Flexible(
                            child: Text(
                              'PN: ${product.partNo}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isOutOfStock
                                    ? const Color(0xFFEF4444)
                                    : (isDark
                                          ? const Color(0xFF38BDF8)
                                          : const Color(0xFF0284C7)),
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            ' • ',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                        if (product.model.isNotEmpty) ...[
                          Flexible(
                            child: Text(
                              product.model,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            ' • ',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                        if (product.costCode.isNotEmpty)
                          Text(
                            'Cost: ${product.costCode}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isInCart) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'In Cart',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              PosStockPill(totalStock: product.stockCount),
              const SizedBox(width: 8),
              Icon(
                isOutOfStock
                    ? Icons.block_rounded
                    : (isInCart
                          ? Icons.check_circle_rounded
                          : Icons.add_shopping_cart_rounded),
                size: 18,
                color: isOutOfStock
                    ? const Color(0xFFEF4444)
                    : (isInCart
                          ? const Color(0xFF10B981)
                          : (isDark
                                ? const Color(0xFF818CF8)
                                : const Color(0xFF6366F1))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
