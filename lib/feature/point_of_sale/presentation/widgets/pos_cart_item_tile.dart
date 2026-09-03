import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/domain/usecases/get_cost_code_mapping.dart';
import 'package:gear_track/core/entities/cost_code_mapping.dart';
import 'package:gear_track/core/theme/app_colors.dart';
import 'package:gear_track/core/utils/currency_formatter.dart';
import 'package:gear_track/feature/inventory/domain/entities/product.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:gear_track/feature/point_of_sale/domain/entities/cart_item.dart';
import 'package:gear_track/feature/point_of_sale/presentation/bloc/pos_bloc.dart';
import 'package:gear_track/feature/point_of_sale/presentation/widgets/pos_stock_pill.dart';
import 'package:gear_track/init_dependencies.dart';

class PosCartItemTile extends StatefulWidget {
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

  @override
  State<PosCartItemTile> createState() => _PosCartItemTileState();
}

class _PosCartItemTileState extends State<PosCartItemTile> {
  static CostCodeMapping? _cachedMapping;
  late CostCodeMapping _mapping;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _mapping = _cachedMapping ?? CostCodeMapping.defaultMapping();
    final initialPriceStr = widget.item.sellPrice > 0
        ? (widget.item.sellPrice % 1 == 0
            ? widget.item.sellPrice.toInt().toString()
            : widget.item.sellPrice.toString())
        : '';
    _priceController = TextEditingController(text: initialPriceStr);
    _priceController.addListener(_onPriceInputChanged);
    if (_cachedMapping == null) {
      _loadMapping();
    }
  }

  void _onPriceInputChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant PosCartItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.sellPrice != widget.item.sellPrice) {
      final currentCtrlVal =
          double.tryParse(_priceController.text.trim()) ?? 0.0;
      if (currentCtrlVal != widget.item.sellPrice) {
        final newText = widget.item.sellPrice > 0
            ? (widget.item.sellPrice % 1 == 0
                ? widget.item.sellPrice.toInt().toString()
                : widget.item.sellPrice.toString())
            : '';
        _priceController.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _priceController.removeListener(_onPriceInputChanged);
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadMapping() async {
    final result = await serviceLocator<GetCostCodeMapping>()();
    result.fold(
      (_) {},
      (mapping) {
        _cachedMapping = mapping;
        if (mounted) {
          setState(() {
            _mapping = mapping;
          });
        }
      },
    );
  }

  void _showPartNoSelector(BuildContext context) {
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

    // Find current item's model if available
    final currentProduct = allProducts
        .where(
          (p) =>
              p.id == widget.item.productId ||
              p.partNo.trim().toUpperCase() ==
                  widget.item.partNo.trim().toUpperCase(),
        )
        .firstOrNull;
    final curModel = currentProduct?.model.trim().toLowerCase() ?? '';

    // Extract ALL individual batches matching this item and model
    final List<Product> matchingBatches = allProducts.where((p) {
      final pName = p.itemName.trim().toLowerCase();
      final curName = widget.item.itemName.trim().toLowerCase();
      final pModel = p.model.trim().toLowerCase();
      final isSameModel = curModel.isEmpty || pModel == curModel;
      return (pName == curName && isSameModel) ||
          p.partNo.trim().toUpperCase() ==
              widget.item.partNo.trim().toUpperCase();
    }).toList();

    final List<Product> targetBatches =
        matchingBatches.isNotEmpty ? matchingBatches : allProducts;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _PartNoSelectorSheet(
        itemName: widget.item.itemName,
        batches: targetBatches,
        selectedPartNo: widget.item.partNo,
        onSelected: (selectedBatch) {
          Navigator.pop(sheetContext);
          widget.onProductChanged?.call(selectedBatch);
        },
        onAddNewCard: (batch) {
          Navigator.pop(sheetContext);
          final cleanProductId = batch.partNo.isNotEmpty
              ? batch.partNo
              : (batch.id.contains('/') ? batch.id.split('/')[0] : batch.id);
          final batchId =
              batch.id.contains('/') ? batch.id.split('/')[1] : batch.id;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Decode cost code to get the buying price per unit
    final buyPrice = _mapping.decode(widget.item.costCode);
    final typedPrice = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final activePrice = _priceController.text.trim().isNotEmpty
        ? typedPrice
        : widget.item.sellPrice;

    // Instant real-time loss indicator
    final isLoss = activePrice > 0 && buyPrice > 0 && activePrice < buyPrice;

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
                  widget.item.itemName,
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
                onTap: widget.removeItem,
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
                      widget.item.partNo.isNotEmpty
                          ? widget.item.partNo
                          : 'Select Part No',
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

              // Unit Price Input Box (turns red immediately when selling below buy price)
              Expanded(child: _buildPriceInput(theme, isLoss)),

              const SizedBox(width: 12),

              // Subtotal Display
              Text(
                widget.item.subtotal.toCurrency(),
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
    final controller = TextEditingController(text: '${widget.item.quantity}');
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
              widget.item.itemName,
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
                isDense: true,
              ),
              onSubmitted: (val) {
                final qty = int.tryParse(val.trim());
                final maxAllowed = widget.item.availableStock > 0
                    ? widget.item.availableStock
                    : 999999;
                if (qty != null && qty > 0) {
                  final capped = qty > maxAllowed ? maxAllowed : qty;
                  widget.onQuantityChanged(capped);
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
              final maxAllowed = widget.item.availableStock > 0
                  ? widget.item.availableStock
                  : 999999;
              if (qty != null && qty > 0) {
                final capped = qty > maxAllowed ? maxAllowed : qty;
                widget.onQuantityChanged(capped);
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
    final canDecrement = widget.item.quantity > 1;
    final canIncrement = widget.item.availableStock <= 0 ||
        widget.item.quantity < widget.item.availableStock;

    return Row(
      children: [
        _HoldableStepperButton(
          key: ValueKey('dec_${widget.item.id}'),
          icon: Icons.remove_rounded,
          enabled: canDecrement,
          tooltip: 'Hold to decrease rapidly',
          onStep: () {
            if (widget.item.quantity > 1) {
              widget.onQuantityChanged(widget.item.quantity - 1);
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
              '${widget.item.quantity}',
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
          key: ValueKey('inc_${widget.item.id}'),
          icon: Icons.add_rounded,
          enabled: canIncrement,
          tooltip: canIncrement
              ? 'Hold to increase rapidly'
              : 'Max available stock reached (${widget.item.availableStock})',
          onStep: () {
            if (canIncrement) {
              widget.onQuantityChanged(widget.item.quantity + 1);
            }
          },
        ),
      ],
    );
  }

  Widget _buildPriceInput(ThemeData theme, bool isLoss) {
    final isDark = theme.brightness == Brightness.dark;

    final fieldBg = isLoss
        ? (isDark
            ? const Color(0xFF450A0A)
            : const Color(0xFFFEE2E2))
        : (isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceContainerLight);

    final borderColor =
        isLoss ? const Color(0xFFDC2626) : Colors.transparent;

    final textColor = isLoss
        ? const Color(0xFFDC2626)
        : (isDark ? Colors.white : const Color(0xFF0F172A));

    final currencyColor = isLoss
        ? const Color(0xFFDC2626)
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: borderColor,
          width: isLoss ? 1.5 : 0,
        ),
      ),
      child: Row(
        children: [
          Text(
            '৳',
            style: TextStyle(
              fontSize: 14,
              color: currencyColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                hintText: '0',
                hintStyle: TextStyle(
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                  fontSize: 14,
                ),
              ),
              onChanged: (val) {
                final parsed = double.tryParse(val.trim()) ?? 0.0;
                widget.onPriceChanged(parsed);
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
  final ValueChanged<Product>? onAddNewCard;

  const _PartNoSelectorSheet({
    required this.itemName,
    required this.batches,
    required this.selectedPartNo,
    required this.onSelected,
    this.onAddNewCard,
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
                              color:
                                  (isDark
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
                                    ? const Color(
                                        0xFF6366F1,
                                      ).withValues(alpha: 0.15)
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

/// Holdable Stepper Button supporting continuous auto-increment / auto-decrement on long press / hold
class _HoldableStepperButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onStep;
  final bool enabled;
  final String tooltip;

  const _HoldableStepperButton({
    super.key,
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

    _initialDelayTimer?.cancel();
    _periodicTimer?.cancel();
    _initialDelayTimer = Timer(const Duration(milliseconds: 300), () {
      _periodicTimer = Timer.periodic(const Duration(milliseconds: 75), (_) {
        if (!widget.enabled || !mounted) {
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
  void didUpdateWidget(covariant _HoldableStepperButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _isPressed) {
      _stopHolding();
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
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = widget.enabled
        ? (_isPressed
            ? (isDark
                ? const Color(0xFF6366F1).withValues(alpha: 0.3)
                : const Color(0xFF4F46E5).withValues(alpha: 0.15))
            : (isDark
                ? AppColors.surfaceContainerDark
                : AppColors.surfaceContainerLight))
        : (isDark
            ? AppColors.surfaceContainerDark.withValues(alpha: 0.4)
            : AppColors.surfaceContainerLight.withValues(alpha: 0.4));

    final iconColor = widget.enabled
        ? (_isPressed
            ? (isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5))
            : (isDark ? Colors.white : const Color(0xFF0F172A)))
        : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8));

    return Tooltip(
      message: widget.tooltip,
      triggerMode: TooltipTriggerMode.manual,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _startHolding(),
        onPointerUp: (_) => _stopHolding(),
        onPointerCancel: (_) => _stopHolding(),
        child: MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(widget.icon, size: 15, color: iconColor),
          ),
        ),
      ),
    );
  }
}
