import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/feature/inventory/domain/entities/grouped_product.dart';
import 'package:gear_track/feature/inventory/domain/entities/product.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:gear_track/feature/inventory/presentation/widgets/batch_item_tile.dart';
import 'package:gear_track/feature/inventory/presentation/widgets/edit_product_sheet.dart';
import 'package:gear_track/feature/inventory/presentation/widgets/stock_status_badge.dart';

class ProductCard extends StatefulWidget {
  final GroupedProduct groupedProduct;
  final VoidCallback? onQuickAdd;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;
  final int cardIndex;
  final String? cardBgAsset;

  const ProductCard({
    super.key,
    required this.groupedProduct,
    this.onQuickAdd,
    this.isExpanded = false,
    this.onToggleExpand,
    this.cardIndex = 0,
    this.cardBgAsset,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  String? _deletingBatchId;

  static const List<String> _cardVariants = [
    'assets/images/card_bg.png',
    'assets/images/card_bg_green.jpg',
    'assets/images/card_bg_gold.jpg',
  ];

  String get _cardBgImage {
    if (widget.cardBgAsset != null) return widget.cardBgAsset!;
    return _cardVariants[widget.cardIndex % _cardVariants.length];
  }

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() => _deletingBatchId = batch.id);
              final completer = Completer<void>();
              context.read<InventoryBloc>().add(
                DeleteProductEvent(batch.id, completer: completer),
              );
              try {
                await completer.future;
              } finally {
                if (mounted) {
                  setState(() => _deletingBatchId = null);
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final grouped = widget.groupedProduct;

    final shadowColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.34);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Background Artwork Image (Fully Visible)
            Positioned.fill(
              child: Image.asset(
                _cardBgImage,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),

            // Translucent Glossy Filter Layer (Image Shines Through Clearly)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 1.8, sigmaY: 1.8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onToggleExpand,
                  child: Container(
                    padding: const EdgeInsets.all(12.0),

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
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),

                                  // Meta Chips Row: Model
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      if (grouped.model.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.18,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.25,
                                              ),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Text(
                                            'Model: ${grouped.model}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),

                            // High-Visibility Stock Status Badge
                            StockStatusBadge(
                              totalStockCount: grouped.totalStockCount,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Controls Row: Combined Batches Pill & Quick Add Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Combined Pill Container: Batch Count & Arrow Toggle Icon
                            InkWell(
                              onTap: widget.onToggleExpand,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.28),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.layers_outlined,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${grouped.batchCount} ${grouped.batchCount == 1 ? 'Batch' : 'Batches'}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    AnimatedRotation(
                                      turns: widget.isExpanded ? 0.5 : 0,
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      child: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Quick Add Stock Frosted Glass Button
                            if (widget.onQuickAdd != null)
                              InkWell(
                                onTap: widget.onQuickAdd,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.28),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.45,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Text(
                                    'Add Stock',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                              const SizedBox(height: 12),
                              // Batch Items Container (Soft Ice-Blue Reference Design)
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isDark
                                        ? [
                                            const Color(0xFF131922),
                                            const Color(0xFF1B232D),
                                          ]
                                        : [
                                            const Color(0xFFDCEBFE),
                                            const Color(0xFFF0F5FF),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF2B3645)
                                        : const Color(0xFFC7DCFA),
                                    width: 1,
                                  ),
                                ),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxHeight: 180,
                                  ),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: grouped.batches.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 4),
                                    itemBuilder: (context, index) {
                                      final batch = grouped.batches[index];
                                      return BatchItemTile(
                                        batch: batch,
                                        index: index,
                                        isDeleting:
                                            _deletingBatchId == batch.id,
                                        onEdit: () => EditProductSheet.show(
                                          context,
                                          batch,
                                        ),
                                        onDelete: () =>
                                            _confirmDelete(context, batch),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          crossFadeState: widget.isExpanded
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
          ],
        ),
      ),
    );
  }
}
