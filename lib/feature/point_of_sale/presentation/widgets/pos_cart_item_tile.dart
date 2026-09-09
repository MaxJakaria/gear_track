import 'package:flutter/material.dart';
import 'package:gear_track/core/domain/usecases/get_cost_code_mapping.dart';
import 'package:gear_track/core/entities/cost_code_mapping.dart';
import 'package:gear_track/core/utils/currency_formatter.dart';
import 'package:gear_track/feature/inventory/domain/entities/product.dart';
import 'package:gear_track/feature/point_of_sale/domain/entities/cart_item.dart';
import 'package:gear_track/feature/point_of_sale/presentation/widgets/pos_cart_item_price_input.dart';
import 'package:gear_track/feature/point_of_sale/presentation/widgets/pos_holdable_stepper_button.dart';
import 'package:gear_track/feature/point_of_sale/presentation/widgets/pos_part_no_selector_sheet.dart';
import 'package:gear_track/feature/point_of_sale/presentation/widgets/pos_quantity_edit_dialog.dart';
import 'package:gear_track/init_dependencies.dart';

/// Single Item Tile Widget in POS Cart with compact 3-row layout:
/// - Row 1: Item Name & Remove Button
/// - Row 2: Part Number Switcher & Stock Indicator
/// - Row 3: Quantity Stepper, Dynamic Price Input & Subtotal
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

  @override
  void initState() {
    super.initState();
    _mapping = _cachedMapping ?? CostCodeMapping.defaultMapping();
    if (_cachedMapping == null) {
      _loadMapping();
    }
  }

  Future<void> _loadMapping() async {
    final result = await serviceLocator<GetCostCodeMapping>()();
    result.fold((_) {}, (mapping) {
      _cachedMapping = mapping;
      if (mounted) {
        setState(() => _mapping = mapping);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOutOfStock = widget.item.availableStock <= 0;
    final buyPrice = _mapping.decode(widget.item.costCode);
    final primaryColor = isDark
        ? const Color(0xFF818CF8)
        : const Color(0xFF6366F1);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isOutOfStock
            ? (isDark
                  ? const Color(0xFF7F1D1D).withValues(alpha: 0.15)
                  : const Color(0xFFFEF2F2))
            : (isDark
                  ? theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    )
                  : Colors.white),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOutOfStock
              ? const Color(0xFFEF4444).withValues(alpha: 0.6)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: isOutOfStock ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Item Name & Remove Action
          _buildHeaderRow(theme),

          const SizedBox(height: 4),

          // Row 2: Part No & Stock Indicator
          _buildMetaRow(context, primaryColor, isDark, isOutOfStock),

          const SizedBox(height: 8),

          // Row 3: Quantity Stepper, Dynamic Price Input & Subtotal
          _buildControlsRow(theme, buyPrice),
        ],
      ),
    );
  }

  /// Row 1: Item Name (expanded for full visibility) and Remove Action
  Widget _buildHeaderRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.item.itemName,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: widget.removeItem,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  /// Row 2: Part Number Selector & Available Stock Status Indicator
  Widget _buildMetaRow(
    BuildContext context,
    Color primaryColor,
    bool isDark,
    bool isOutOfStock,
  ) {
    return Row(
      children: [
        _buildPartNoButton(context, primaryColor),
        const SizedBox(width: 6),
        _buildStockIndicator(isDark, isOutOfStock),
      ],
    );
  }

  /// Part Number Switcher Button with Dropdown Indicator
  Widget _buildPartNoButton(BuildContext context, Color primaryColor) {
    return InkWell(
      onTap: () => PosPartNoSelectorSheet.show(
        context,
        productId: widget.item.productId,
        partNo: widget.item.partNo,
        itemName: widget.item.itemName,
        onProductChanged: widget.onProductChanged,
      ),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.35),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_2_rounded, size: 11, color: primaryColor),
            const SizedBox(width: 3),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 105),
              child: Text(
                widget.item.partNo.isNotEmpty ? widget.item.partNo : 'Part No',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down_rounded, size: 15, color: primaryColor),
          ],
        ),
      ),
    );
  }

  /// Stock status badge (In Stock count or Out of Stock alert)
  Widget _buildStockIndicator(bool isDark, bool isOutOfStock) {
    if (isOutOfStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.5),
            width: 0.8,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_rounded, size: 10, color: Color(0xFFEF4444)),
            SizedBox(width: 3),
            Text(
              'Out of Stock',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 10,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 3),
          Text(
            '${widget.item.availableStock}',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  /// Row 3: Stepper + Dynamic Price Input + Calculated Subtotal
  Widget _buildControlsRow(ThemeData theme, double buyPrice) {
    return Row(
      children: [
        // Quantity Stepper
        _buildQuantityStepper(theme),

        const SizedBox(width: 10),

        // Isolated Price Input (self-contained state & real-time loss color)
        Expanded(
          child: PosCartItemPriceInput(
            sellPrice: widget.item.sellPrice,
            buyPrice: buyPrice,
            onPriceChanged: widget.onPriceChanged,
          ),
        ),

        const SizedBox(width: 10),

        // Subtotal
        Text(
          widget.item.subtotal.toCurrency(),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF00A859),
          ),
        ),
      ],
    );
  }

  /// Quantity Stepper with Hold-to-Repeat buttons and tap-to-type dialog
  Widget _buildQuantityStepper(ThemeData theme) {
    final isOutOfStock = widget.item.availableStock <= 0;
    final canDecrement = !isOutOfStock && widget.item.quantity > 1;
    final canIncrement =
        !isOutOfStock && widget.item.quantity < widget.item.availableStock;

    return Row(
      children: [
        PosHoldableStepperButton(
          key: ValueKey('dec_${widget.item.id}'),
          icon: Icons.remove_rounded,
          enabled: canDecrement,
          tooltip: isOutOfStock
              ? 'Item is out of stock'
              : 'Hold to decrease rapidly',
          onStep: () {
            if (widget.item.quantity > 1) {
              widget.onQuantityChanged(widget.item.quantity - 1);
            }
          },
        ),
        InkWell(
          onTap: isOutOfStock
              ? null
              : () => PosQuantityEditDialog.show(
                  context,
                  itemName: widget.item.itemName,
                  initialQuantity: widget.item.quantity,
                  availableStock: widget.item.availableStock,
                  onQuantityChanged: widget.onQuantityChanged,
                ),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            constraints: const BoxConstraints(minWidth: 26),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Text(
              '${widget.item.quantity}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: isOutOfStock
                    ? const Color(0xFFEF4444)
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
        PosHoldableStepperButton(
          key: ValueKey('inc_${widget.item.id}'),
          icon: Icons.add_rounded,
          enabled: canIncrement,
          tooltip: isOutOfStock
              ? 'Item is out of stock'
              : (canIncrement
                    ? 'Hold to increase rapidly'
                    : 'Max available stock reached (${widget.item.availableStock})'),
          onStep: () {
            if (canIncrement) {
              widget.onQuantityChanged(widget.item.quantity + 1);
            }
          },
        ),
      ],
    );
  }
}
