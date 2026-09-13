import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/feature/inventory/domain/entities/product.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:gear_track/feature/point_of_sale/presentation/bloc/pos_bloc.dart';
import 'package:gear_track/feature/point_of_sale/presentation/widgets/pos_stock_pill.dart';

/// Modal bottom sheet for selecting and switching batch / part number of an item in the cart
class PosPartNoSelectorSheet extends StatelessWidget {
  final String itemName;
  final List<Product> batches;
  final String selectedPartNo;
  final ValueChanged<Product> onSelected;
  final ValueChanged<Product>? onAddNewCard;

  const PosPartNoSelectorSheet({
    super.key,
    required this.itemName,
    required this.batches,
    required this.selectedPartNo,
    required this.onSelected,
    this.onAddNewCard,
  });

  /// Static helper to find matching batches from inventory and show the selector modal
  static void show(
    BuildContext context, {
    required String productId,
    required String partNo,
    required String itemName,
    required ValueChanged<Product>? onProductChanged,
  }) {
    final inventoryState = context.read<InventoryBloc>().state;
    final List<Product> allProducts =
        inventoryState is InventoryLoaded ? inventoryState.products : [];

    if (allProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No products available in inventory.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final currentProduct = allProducts
        .where(
          (p) =>
              p.id == productId ||
              p.partNo.trim().toUpperCase() == partNo.trim().toUpperCase(),
        )
        .firstOrNull;
    final curModel = currentProduct?.model.trim().toLowerCase() ?? '';

    final List<Product> matchingBatches = allProducts.where((p) {
      final pName = p.itemName.trim().toLowerCase();
      final curName = itemName.trim().toLowerCase();
      final pModel = p.model.trim().toLowerCase();
      final isSameModel = curModel.isEmpty || pModel == curModel;
      return (pName == curName && isSameModel) ||
          p.partNo.trim().toUpperCase() == partNo.trim().toUpperCase();
    }).toList();

    final List<Product> targetBatches =
        matchingBatches.isNotEmpty ? matchingBatches : allProducts;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => PosPartNoSelectorSheet(
        itemName: itemName,
        batches: targetBatches,
        selectedPartNo: partNo,
        onSelected: (selectedBatch) {
          Navigator.pop(sheetContext);
          onProductChanged?.call(selectedBatch);
        },
        onAddNewCard: (batch) {
          Navigator.pop(sheetContext);
          final cleanProductId = batch.id.contains('/')
              ? batch.id.split('/')[0]
              : batch.id;
          final batchId =
              batch.id.contains('/') ? batch.id.split('/')[1] : '';

          context.read<PosBloc>().add(
            AddToCartEvent(
              productId: cleanProductId,
              batchId: batchId,
              itemName: batch.itemName,
              partNo: batch.partNo,
              costCode: batch.costCode,
              availableStock: batch.stockCount,
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final maxHeight = MediaQuery.of(context).size.height * 0.60;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 16,
        right: 16,
        bottom: bottomPadding + 16,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.qr_code_2_rounded,
                            size: 17,
                            color: isDark
                                ? const Color(0xFF818CF8)
                                : const Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Select Part Number',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: (isDark
                                      ? const Color(0xFF818CF8)
                                      : const Color(0xFF6366F1))
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${batches.length}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFF818CF8)
                                    : const Color(0xFF6366F1),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        itemName,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Flexible(
              child: batches.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'No part numbers available for this product.',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: batches.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.35,
                        ),
                      ),
                      itemBuilder: (context, index) {
                        final batch = batches[index];
                        final isSelected =
                            batch.partNo.trim().toUpperCase() ==
                            selectedPartNo.trim().toUpperCase();
                        final isOutOfStock = batch.stockCount <= 0;

                        return Container(
                          color: isSelected
                              ? (isDark
                                  ? const Color(0xFF6366F1)
                                      .withValues(alpha: 0.15)
                                  : const Color(0xFFEEF2FF))
                              : Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 6,
                          ),
                          child: Opacity(
                            opacity: isOutOfStock ? 0.45 : 1.0,
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: isOutOfStock
                                        ? () {
                                            ScaffoldMessenger.of(context)
                                                .clearSnackBars();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '${batch.partNo.isNotEmpty ? batch.partNo : 'This batch'} is Out of Stock!',
                                                ),
                                                backgroundColor:
                                                    const Color(0xFFDC2626),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        : () => onSelected(batch),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                batch.partNo,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: isOutOfStock
                                                      ? const Color(0xFFEF4444)
                                                      : (isDark
                                                          ? const Color(
                                                              0xFF818CF8,
                                                            )
                                                          : const Color(
                                                              0xFF6366F1,
                                                            )),
                                                ),
                                              ),
                                              if (isSelected) ...[
                                                const SizedBox(width: 5),
                                                Icon(
                                                  Icons.check_circle_rounded,
                                                  size: 15,
                                                  color: isDark
                                                      ? const Color(0xFF818CF8)
                                                      : const Color(0xFF6366F1),
                                                ),
                                              ],
                                            ],
                                          ),
                                          if (batch.model.isNotEmpty) ...[
                                            const SizedBox(height: 1),
                                            Text(
                                              'Model: ${batch.model}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          const SizedBox(height: 1),
                                          Row(
                                            children: [
                                              if (batch.costCode.isNotEmpty)
                                                Text(
                                                  'Cost: ${batch.costCode}',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurfaceVariant
                                                        .withValues(
                                                          alpha: 0.85,
                                                        ),
                                                  ),
                                                ),
                                              Text(
                                                ' • Date: ${_formatDate(batch.entryDate)}',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant
                                                      .withValues(alpha: 0.7),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                PosStockPill(totalStock: batch.stockCount),
                                if (onAddNewCard != null) ...[
                                  const SizedBox(width: 4),
                                  Tooltip(
                                    message: isOutOfStock
                                        ? 'Out of stock'
                                        : 'Add as separate sales card',
                                    child: IconButton(
                                      icon: Icon(
                                        isOutOfStock
                                            ? Icons.block_rounded
                                            : Icons.add_shopping_cart_rounded,
                                        size: 18,
                                      ),
                                      color: isOutOfStock
                                          ? const Color(0xFFEF4444)
                                          : (isDark
                                              ? const Color(0xFF818CF8)
                                              : const Color(0xFF6366F1)),
                                      onPressed: isOutOfStock
                                          ? null
                                          : () => onAddNewCard?.call(batch),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
