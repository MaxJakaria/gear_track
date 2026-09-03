import 'package:flutter/material.dart';
import 'package:gear_track/core/theme/app_colors.dart';
import 'package:gear_track/core/utils/currency_formatter.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';

/// Minimalist, high-end item return tile matching GearTrack's luxury UI
class ReturnItemTile extends StatelessWidget {
  final InvoiceItemEntity item;
  final int selectedQuantity;
  final bool restock;
  final String reason;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<bool> onRestockChanged;
  final ValueChanged<String> onReasonChanged;

  const ReturnItemTile({
    super.key,
    required this.item,
    required this.selectedQuantity,
    required this.restock,
    required this.reason,
    required this.onQuantityChanged,
    required this.onRestockChanged,
    required this.onReasonChanged,
  });

  static const List<String> returnReasons = [
    'Defective / Damaged',
    'Wrong Item Delivered',
    'Customer Changed Mind',
    'Size / Fit Issue',
    'Exchange for Another Item',
    'Other Reason',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final maxReturnable = item.returnableQuantity;
    final isFullyReturned = maxReturnable <= 0;
    final isSelected = selectedQuantity > 0;

    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    final toggleSelection = () {
      if (isFullyReturned) return;
      if (isSelected) {
        onQuantityChanged(0);
      } else {
        onQuantityChanged(selectedQuantity > 0 ? selectedQuantity : 1);
      }
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isFullyReturned
            ? (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC))
            : cardBg,
        borderRadius: BorderRadius.circular(8),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color:
                      (isDark
                              ? AppColors.primaryButtonDark
                              : AppColors.primaryButtonLight)
                          .withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isFullyReturned ? null : toggleSelection,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Item name, details & Unit price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selection Circle
                    if (!isFullyReturned)
                      Padding(
                        padding: const EdgeInsets.only(right: 12, top: 2),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? (isDark
                                      ? AppColors.primaryButtonDark
                                      : AppColors.primaryButtonLight)
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? (isDark
                                        ? AppColors.primaryButtonDark
                                        : AppColors.primaryButtonLight)
                                  : (isDark
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFFCBD5E1)),
                              width: 1.8,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.itemName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: isFullyReturned
                                  ? (isDark ? Colors.white38 : Colors.black38)
                                  : (isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A)),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (item.partNo.isNotEmpty) ...[
                                Text(
                                  item.partNo,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                'Sold: ${item.quantity}  •  Avail: $maxReturnable',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.sellPrice.toCurrency(),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: isFullyReturned
                                ? (isDark ? Colors.white38 : Colors.black38)
                                : (isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A)),
                          ),
                        ),
                        Text(
                          'each',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // If fully returned
                if (isFullyReturned) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 13,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Already fully refunded',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Interactive Stepper & Options if item is selected
                if (isSelected) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, thickness: 0.7),
                  const SizedBox(height: 10),

                  // Stepper + Item Refund Subtotal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Stepper
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildStepperBtn(
                              icon: Icons.remove,
                              onPressed: selectedQuantity > 0
                                  ? () =>
                                        onQuantityChanged(selectedQuantity - 1)
                                  : null,
                              isDark: isDark,
                            ),
                            Container(
                              constraints: const BoxConstraints(minWidth: 34),
                              alignment: Alignment.center,
                              child: Text(
                                '$selectedQuantity',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            _buildStepperBtn(
                              icon: Icons.add,
                              onPressed: selectedQuantity < maxReturnable
                                  ? () =>
                                        onQuantityChanged(selectedQuantity + 1)
                                  : null,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),

                      // Quick "All" shortcut if max > 1
                      if (maxReturnable > 1 && selectedQuantity < maxReturnable)
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => onQuantityChanged(maxReturnable),
                          child: Text(
                            'Max ($maxReturnable)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.primaryButtonDark
                                  : AppColors.primaryButtonLight,
                            ),
                          ),
                        ),

                      // Refund Subtotal
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Refund: ',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            (selectedQuantity * item.sellPrice).toCurrency(),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? const Color(0xFFF87171)
                                  : const Color(0xFFE11D48),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Restock Checkbox
                  InkWell(
                    onTap: () => onRestockChanged(!restock),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            height: 18,
                            width: 18,
                            child: Checkbox(
                              value: restock,
                              onChanged: (val) {
                                if (val != null) onRestockChanged(val);
                              },
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              activeColor: isDark
                                  ? AppColors.primaryButtonDark
                                  : AppColors.primaryButtonLight,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Restock',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF334155),
                            ),
                          ),
                          if (!restock) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFEF4444,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Damaged / Scrap',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Reason Selector
                  Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: returnReasons.contains(reason)
                            ? reason
                            : returnReasons.first,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF334155),
                        ),
                        dropdownColor: isDark
                            ? const Color(0xFF1E293B)
                            : Colors.white,
                        items: returnReasons.map((r) {
                          return DropdownMenuItem<String>(
                            value: r,
                            child: Text(r, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) onReasonChanged(val);
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepperBtn({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Icon(
          icon,
          size: 16,
          color: onPressed == null
              ? (isDark ? Colors.white24 : Colors.black26)
              : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
    );
  }
}
