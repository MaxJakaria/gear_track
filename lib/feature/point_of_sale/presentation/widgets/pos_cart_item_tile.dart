import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/utils/currency_formatter.dart';
import 'package:gear_track/feature/inventory/domain/entities/product.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:gear_track/feature/point_of_sale/domain/entities/cart_item.dart';
import 'package:gear_track/feature/point_of_sale/presentation/widgets/pos_stock_pill.dart';

class PosCartItemTile extends StatelessWidget {
  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<double> onPriceChanged;
  final ValueChanged<Product>? onProductChanged;
  final VoidCallback removeItem;

  const PosCartItemTile({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onPriceChanged,
    this.onProductChanged,
    required this.removeItem,
  });

  void _showPartNoSelector(BuildContext context) {
    final inventoryState = context.read<InventoryBloc>().state;
    final List<Product> allProducts = inventoryState is InventoryLoaded
        ? inventoryState.products
        : [];

    if (allProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No products available in inventory.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Extract ALL individual batches matching this item name
    final List<Product> matchingBatches = allProducts.where((p) {
      final pName = p.itemName.trim().toLowerCase();
      final curName = item.itemName.trim().toLowerCase();
      return pName == curName ||
          p.partNo.trim().toUpperCase() == item.partNo.trim().toUpperCase();
    }).toList();

    final List<Product> targetBatches = matchingBatches.isNotEmpty
        ? matchingBatches
        : allProducts;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _PartNoSelectorSheet(
        itemName: item.itemName,
        batches: targetBatches,
        selectedPartNo: item.partNo,
        onSelected: (selectedBatch) {
          Navigator.pop(sheetContext);
          onProductChanged?.call(selectedBatch);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Header: Name & Remove Action
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.itemName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: removeItem,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Part No Dropdown Selector Pill Button
          InkWell(
            onTap: () => _showPartNoSelector(context),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:
                    (isDark ? const Color(0xFF818CF8) : const Color(0xFF6366F1))
                        .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color:
                      (isDark
                              ? const Color(0xFF818CF8)
                              : const Color(0xFF6366F1))
                          .withValues(alpha: 0.35),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code_2_rounded,
                    size: 13,
                    color: isDark
                        ? const Color(0xFF818CF8)
                        : const Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      item.partNo.isNotEmpty ? item.partNo : 'Select Part No',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFF818CF8)
                            : const Color(0xFF6366F1),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 18,
                    color: isDark
                        ? const Color(0xFF818CF8)
                        : const Color(0xFF6366F1),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Controls Row: Quantity Stepper, Unit Price Input & Subtotal
          Row(
            children: [
              // Quantity Stepper [-] Qty [+]
              _buildQuantityStepper(theme, context),

              const SizedBox(width: 12),

              // Unit Price Input Box
              Expanded(child: _buildPriceInput(theme)),

              const SizedBox(width: 12),

              // Subtotal Display
              Text(
                item.subtotal.toCurrency(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF00A859), // Vibrant green
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showQuantityEditDialog(BuildContext context) {
    final controller = TextEditingController(text: '${item.quantity}');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Set Quantity',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.itemName,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (val) {
                final qty = int.tryParse(val.trim());
                if (qty != null && qty > 0) {
                  onQuantityChanged(qty);
                  Navigator.pop(dialogContext);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final qty = int.tryParse(controller.text.trim());
              if (qty != null && qty > 0) {
                onQuantityChanged(qty);
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityStepper(ThemeData theme, BuildContext context) {
    final canDecrement = item.quantity > 1;

    return Row(
      children: [
        _HoldableStepperButton(
          icon: Icons.remove_rounded,
          enabled: canDecrement,
          tooltip: 'Hold to decrease rapidly',
          onStep: () {
            if (item.quantity > 1) {
              onQuantityChanged(item.quantity - 1);
            }
          },
        ),
        InkWell(
          onTap: () => _showQuantityEditDialog(context),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            constraints: const BoxConstraints(minWidth: 34),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
        _HoldableStepperButton(
          icon: Icons.add_rounded,
          enabled: true,
          tooltip: 'Hold to increase rapidly',
          onStep: () => onQuantityChanged(item.quantity + 1),
        ),
      ],
    );
  }

  Widget _buildPriceInput(ThemeData theme) {
    final initialPriceStr = item.sellPrice > 0
        ? (item.sellPrice % 1 == 0
              ? item.sellPrice.toInt().toString()
              : item.sellPrice.toString())
        : '';

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Text(
            '৳',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextFormField(
              initialValue: initialPriceStr,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: InputBorder.none,
                hintText: '0',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                  fontSize: 14,
                ),
              ),
              onChanged: (val) {
                final parsed = double.tryParse(val.trim()) ?? 0.0;
                onPriceChanged(parsed);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PartNoSelectorSheet extends StatelessWidget {
  final String itemName;
  final List<Product> batches;
  final String selectedPartNo;
  final ValueChanged<Product> onSelected;

  const _PartNoSelectorSheet({
    required this.itemName,
    required this.batches,
    required this.selectedPartNo,
    required this.onSelected,
  });

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
    final maxHeight = MediaQuery.of(context).size.height * 0.55;
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

                        return InkWell(
                          onTap: () => onSelected(batch),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            color: isSelected
                                ? (isDark
                                      ? const Color(
                                          0xFF6366F1,
                                        ).withValues(alpha: 0.15)
                                      : const Color(0xFFEEF2FF))
                                : Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 9,
                            ),
                            child: Row(
                              children: [
                                Expanded(
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
                                              color: isDark
                                                  ? const Color(0xFF818CF8)
                                                  : const Color(0xFF6366F1),
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
                                                    .withValues(alpha: 0.85),
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
                                const SizedBox(width: 8),
                                PosStockPill(totalStock: batch.stockCount),
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

/// Holdable Stepper Button supporting continuous auto-increment / auto-decrement on long press
class _HoldableStepperButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onStep;
  final bool enabled;
  final String tooltip;

  const _HoldableStepperButton({
    required this.icon,
    required this.onStep,
    this.enabled = true,
    this.tooltip = '',
  });

  @override
  State<_HoldableStepperButton> createState() => _HoldableStepperButtonState();
}

class _HoldableStepperButtonState extends State<_HoldableStepperButton> {
  Timer? _initialDelayTimer;
  Timer? _periodicTimer;
  bool _isPressed = false;

  void _startHolding() {
    if (!widget.enabled) return;
    setState(() => _isPressed = true);
    widget.onStep();

    _initialDelayTimer = Timer(const Duration(milliseconds: 320), () {
      _periodicTimer = Timer.periodic(const Duration(milliseconds: 75), (_) {
        if (!widget.enabled) {
          _stopHolding();
          return;
        }
        widget.onStep();
      });
    });
  }

  void _stopHolding() {
    _initialDelayTimer?.cancel();
    _periodicTimer?.cancel();
    _initialDelayTimer = null;
    _periodicTimer = null;
    if (_isPressed && mounted) {
      setState(() => _isPressed = false);
    }
  }

  @override
  void dispose() {
    _stopHolding();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final baseColor = widget.enabled
        ? (_isPressed
            ? theme.colorScheme.primary.withValues(alpha: 0.2)
            : theme.colorScheme.surfaceContainerHighest)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35);

    final iconColor = widget.enabled
        ? (_isPressed
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant)
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35);

    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _startHolding(),
        onTapUp: (_) => _stopHolding(),
        onTapCancel: () => _stopHolding(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: _isPressed
                  ? theme.colorScheme.primary.withValues(alpha: 0.45)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              width: 0.8,
            ),
          ),
          child: Icon(widget.icon, size: 15, color: iconColor),
        ),
      ),
    );
  }
}
