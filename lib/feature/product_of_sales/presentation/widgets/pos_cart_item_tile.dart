import 'package:flutter/material.dart';
import 'package:gear_track/core/utils/currency_formatter.dart';
import 'package:gear_track/feature/product_of_sales/domain/entities/cart_item.dart';

class PosCartItemTile extends StatelessWidget {
  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<double> onPriceChanged;
  final VoidCallback removeItem;

  const PosCartItemTile({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onPriceChanged,
    required this.removeItem,
  });

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
          // Item Header: Name, Part Code & Remove Action
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.partNo,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF818CF8)
                            : const Color(0xFF6366F1),
                      ),
                    ),
                  ],
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

          const SizedBox(height: 10),

          // Controls Row: Quantity Stepper, Unit Price Input & Subtotal
          Row(
            children: [
              // Quantity Stepper [-] Qty [+]
              _buildQuantityStepper(theme),

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

  Widget _buildQuantityStepper(ThemeData theme) {
    return Row(
      children: [
        _buildStepperButton(
          theme: theme,
          icon: Icons.remove_rounded,
          onTap: () {
            if (item.quantity > 1) {
              onQuantityChanged(item.quantity - 1);
            }
          },
        ),
        SizedBox(
          width: 32,
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
        _buildStepperButton(
          theme: theme,
          icon: Icons.add_rounded,
          onTap: () => onQuantityChanged(item.quantity + 1),
        ),
      ],
    );
  }

  Widget _buildStepperButton({
    required ThemeData theme,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
      ),
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
