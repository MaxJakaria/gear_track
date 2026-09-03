import 'package:flutter/material.dart';
import 'package:gear_track/core/utils/currency_formatter.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';

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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFE11D48).withValues(alpha: 0.8)
              : (isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0)),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFFE11D48).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Item Name, Part No, Unit Price & Return Status
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (item.partNo.isNotEmpty)
                      Text(
                        'P/N: ${item.partNo}',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Unit Price',
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

          const SizedBox(height: 10),

          // Row 2: Purchase & Return Stats Chips
          Row(
            children: [
              _buildPill(
                label: 'Purchased: ${item.quantity}',
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                textColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              ),
              const SizedBox(width: 6),
              if (item.returnedQuantity > 0) ...[
                _buildPill(
                  label: 'Prev. Returned: ${item.returnedQuantity}',
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  textColor: const Color(0xFFEF4444),
                ),
                const SizedBox(width: 6),
              ],
              _buildPill(
                label: isFullyReturned ? 'Fully Returned' : 'Returnable: $maxReturnable',
                color: isFullyReturned
                    ? const Color(0xFF64748B).withValues(alpha: 0.15)
                    : const Color(0xFF10B981).withValues(alpha: 0.15),
                textColor: isFullyReturned
                    ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
                    : const Color(0xFF10B981),
              ),
            ],
          ),

          // If fully returned, no further return action is allowed
          if (isFullyReturned) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF64748B)),
                  SizedBox(width: 6),
                  Text(
                    'All purchased quantities have already been refunded.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 0.8),
            const SizedBox(height: 10),

            // Stepper & Refund Subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Qty to Return: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Decrement Button
                    IconButton(
                      onPressed: selectedQuantity > 0
                          ? () => onQuantityChanged(selectedQuantity - 1)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline, size: 22),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      color: const Color(0xFFE11D48),
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 32),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE11D48).withValues(alpha: 0.12)
                            : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$selectedQuantity',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isSelected
                              ? const Color(0xFFE11D48)
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ),
                    // Increment Button
                    IconButton(
                      onPressed: selectedQuantity < maxReturnable
                          ? () => onQuantityChanged(selectedQuantity + 1)
                          : null,
                      icon: const Icon(Icons.add_circle_outline, size: 22),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      color: const Color(0xFF10B981),
                    ),
                  ],
                ),
                if (isSelected)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        (selectedQuantity * item.sellPrice).toCurrency(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFE11D48),
                        ),
                      ),
                      const Text(
                        'Refund',
                        style: TextStyle(fontSize: 10, color: Color(0xFFE11D48)),
                      ),
                    ],
                  ),
              ],
            ),

            // Additional return options if this item is selected for return
            if (isSelected) ...[
              const SizedBox(height: 10),
              // Restock Toggle
              InkWell(
                onTap: () => onRestockChanged(!restock),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: restock,
                          onChanged: (val) => onRestockChanged(val ?? true),
                          activeColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          restock
                              ? 'Restock into inventory (+ stock count)'
                              : 'Do NOT restock (Item damaged / scrap)',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: restock
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 6),
              // Reason Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                    width: 0.8,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: returnReasons.contains(reason) ? reason : returnReasons.first,
                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    items: returnReasons.map((r) {
                      return DropdownMenuItem<String>(
                        value: r,
                        child: Text(r),
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
        ],
      ),
    );
  }

  Widget _buildPill({
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
