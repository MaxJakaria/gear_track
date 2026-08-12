import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/feature/inventory/domain/entities/grouped_product.dart';
import 'package:gear_track/feature/inventory/domain/entities/product.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:gear_track/feature/inventory/presentation/widgets/batch_item_tile.dart';
import 'package:gear_track/feature/inventory/presentation/widgets/edit_product_sheet.dart';
import 'package:gear_track/feature/inventory/presentation/widgets/stock_status_badge.dart';
import 'package:gear_track/feature/inventory/presentation/widgets/tech_chip.dart';

class ProductCard extends StatelessWidget {
  final GroupedProduct groupedProduct;
  final VoidCallback? onQuickAdd;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;

  const ProductCard({
    super.key,
    required this.groupedProduct,
    this.onQuickAdd,
    this.isExpanded = false,
    this.onToggleExpand,
  });

  String _formatDate(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  void _confirmDelete(BuildContext context, Product batch) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F)),
            SizedBox(width: 8),
            Text('Delete Batch Entry'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this stock batch?\n\n'
          '• Cost Code: ${batch.costCode}\n'
          '• Quantity: ${batch.stockCount} units\n'
          '• Entry Date: ${_formatDate(batch.entryDate)}',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<InventoryBloc>().add(DeleteProductEvent(batch.id));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupedProduct;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            spreadRadius: 0,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // 1. Background Artwork Image
            Positioned.fill(
              child: Image.asset(
                'assets/images/card_bg.png',
                fit: BoxFit.cover,
              ),
            ),

            // 2. Real Hardware-Accelerated Blurry Glossy Filter Layer with LinearGradient Overlay
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 1.8, sigmaY: 1.8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color.fromARGB(
                        255,
                        45,
                        67,
                        79,
                      ).withValues(alpha: 0.25),
                      Colors.white.withValues(alpha: 0.25),
                    ],
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onToggleExpand,
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: grouped.totalStockCount <= 0
                                ? const Color(0xFFD32F2F)
                                : const Color(0xFF2E7D32),
                            width: 4,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Section: Title & Stock Status Badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      grouped.itemName.isNotEmpty
                                          ? grouped.itemName
                                          : 'Unnamed Product',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1E242B),
                                        letterSpacing: -0.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        TechChip(
                                          icon: Icons.qr_code_2_rounded,
                                          label: 'Part No: ${grouped.partNo}',
                                          borderColor: const Color(
                                            0xFFD32F2F,
                                          ).withValues(alpha: 0.4),
                                          textColor: const Color(0xFF2C323B),
                                        ),
                                        TechChip(
                                          icon: Icons
                                              .precision_manufacturing_outlined,
                                          label: 'Model: ${grouped.model}',
                                          borderColor: const Color(
                                            0xFF4A515A,
                                          ).withValues(alpha: 0.3),
                                          textColor: const Color(0xFF38404A),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Right Side: Stock Badge & Quick Add Button
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  StockStatusBadge(
                                    totalStockCount: grouped.totalStockCount,
                                  ),
                                  if (onQuickAdd != null) ...[
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: onQuickAdd,
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD32F2F),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFFD32F2F,
                                              ).withValues(alpha: 0.35),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.add_rounded,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 3),
                                            Text(
                                              'Add',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Metrics Strip: Batch Count & Expand Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.layers_outlined,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${grouped.batchCount} ${grouped.batchCount == 1 ? 'Batch' : 'Batches'}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),

                              // Expand/Collapse Interactive Circle Button
                              AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.42),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: Color(0xFF2C323B),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Expandable Batch History Section
                          AnimatedCrossFade(
                            firstChild: const SizedBox.shrink(),
                            secondChild: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(
                                    height: 1,
                                    color: Color(0xFFCFD5DC),
                                  ),
                                ),
                                const SizedBox(height: 2),

                                // Batch Items List
                                ...grouped.batches.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final batch = entry.value;

                                  return BatchItemTile(
                                    batch: batch,
                                    index: index,
                                    onEdit: () =>
                                        EditProductSheet.show(context, batch),
                                    onDelete: () =>
                                        _confirmDelete(context, batch),
                                  );
                                }),
                              ],
                            ),
                            crossFadeState: isExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 250),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
