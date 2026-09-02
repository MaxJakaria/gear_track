import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/feature/inventory/domain/entities/product.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:gear_track/feature/point_of_sale/presentation/widgets/pos_stock_pill.dart';

/// "Find & Add Product" Card Component - Direct Batch Level Search & Add
class PosProductSearchCard extends StatefulWidget {
  final ValueChanged<Product> onProductSelected;

  const PosProductSearchCard({super.key, required this.onProductSelected});

  @override
  State<PosProductSearchCard> createState() => _PosProductSearchCardState();
}

class _PosProductSearchCardState extends State<PosProductSearchCard> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Header
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF3F51B5), // Blue pill
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Find & Add Product',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Search Field Input Box
          _buildSearchInputField(theme),

          // Live Inventory Search Results List
          _buildSearchResultsList(theme),
        ],
      ),
    );
  }

  Widget _buildSearchInputField(ThemeData theme) {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      enableSuggestions: false,
      onChanged: (val) {
        setState(() {
          _searchQuery = val.trim().toLowerCase();
        });
      },
      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search by part no, product name, or model...',
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          fontSize: 12,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: theme.colorScheme.onSurfaceVariant,
          size: 18,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 34,
          minHeight: 20,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 34,
          minHeight: 20,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _clearSearch,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(
                    Icons.clear_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : const SizedBox(width: 34, height: 20),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
      ),
    );
  }

  Widget _buildSearchResultsList(ThemeData theme) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is InventoryLoaded) {
          final allProducts = state.products;
          final q = _searchQuery.trim().toLowerCase();

          final filteredBatches = q.isEmpty
              ? <Product>[]
              : allProducts
                    .where((p) {
                      final nameMatch = p.itemName.toLowerCase().contains(q);
                      final modelMatch = p.model.toLowerCase().contains(q);
                      final partMatch = p.partNo.toLowerCase().contains(q);

                      return nameMatch || modelMatch || partMatch;
                    })
                    .take(10)
                    .toList();

          if (q.isNotEmpty && filteredBatches.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Center(
                child: Text(
                  'No matching products or batches found',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }

          if (filteredBatches.isEmpty) {
            return const SizedBox.shrink();
          }

          return Container(
            margin: const EdgeInsets.only(top: 12),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredBatches.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              itemBuilder: (context, index) {
                final productBatch = filteredBatches[index];

                return _PosDirectSearchResultTile(
                  product: productBatch,
                  onTap: () {
                    // Prevent adding out-of-stock items (stock <= 0) to cart
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

                    widget.onProductSelected(productBatch);
                    _clearSearch();
                  },
                );
              },
            ),
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
  final VoidCallback onTap;

  const _PosDirectSearchResultTile({
    required this.product,
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
              PosStockPill(totalStock: product.stockCount),
              const SizedBox(width: 8),
              Icon(
                isOutOfStock
                    ? Icons.block_rounded
                    : Icons.add_shopping_cart_rounded,
                size: 18,
                color: isOutOfStock
                    ? const Color(0xFFEF4444)
                    : (isDark
                          ? const Color(0xFF818CF8)
                          : const Color(0xFF6366F1)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
