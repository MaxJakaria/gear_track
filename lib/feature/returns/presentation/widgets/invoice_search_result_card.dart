import 'package:flutter/material.dart';
import 'package:gear_track/core/theme/app_colors.dart';
import 'package:gear_track/core/utils/currency_formatter.dart';
import 'package:gear_track/core/widgets/app_gradient_button.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';

/// Ultra-minimalist, professional industry-standard invoice card for returns.
/// Styled after modern fintech / enterprise standards (Apple, Linear, Stripe):
/// - Clean surface with hairline borders and zero visual clutter.
/// - Crisp typography and tabular alignment.
/// - Quiet status dots and subtle indicators instead of loud badges.
/// - Seamless item ledger with clean availability indicators.
/// - Single, prominent "Proceed to Return Invoice" button at the bottom.
class InvoiceSearchResultCard extends StatelessWidget {
  final InvoiceEntity invoice;
  final VoidCallback onProceedToReturn;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const InvoiceSearchResultCard({
    super.key,
    required this.invoice,
    required this.onProceedToReturn,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final customerName = invoice.partyName.trim().isNotEmpty
        ? invoice.partyName.trim()
        : 'Walk-in Customer';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isExpanded
              ? (isDark
                    ? AppColors.primaryButtonDark.withValues(alpha: 0.6)
                    : AppColors.primaryButtonLight.withValues(alpha: 0.5))
              : borderColor,
          width: isExpanded ? 1.0 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Collapsed Header Card (Tap to Expand)
            InkWell(
              onTap: onToggleExpand,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Row: Customer Name & Invoice Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            customerName,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          invoice.totalAmount.toCurrency(),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Bottom Row: Invoice ID Tag, Date, and Status Badge
                    Row(
                      children: [
                        // Invoice ID Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.5,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            invoice.invoiceId,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Sale Date
                        Text(
                          invoice.formattedDate,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),

                        const Spacer(),

                        // Chevron
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Expanded Item Ledger
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Divider(
                    height: 1,
                    thickness: 0.6,
                    color: borderColor.withValues(alpha: 0.8),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Items Header
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'SOLD PRODUCTS (${invoice.items.length})',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),

                        // Items List (Clean ledger without per-item button)
                        ...invoice.items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final bool isItemReturnable =
                              item.returnableQuantity > 0;
                          final bool isLast = index == invoice.items.length - 1;

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Product Title & Subtitle
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.itemName,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF0F172A),
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
                                                    color: isDark
                                                        ? const Color(
                                                            0xFF94A3B8,
                                                          )
                                                        : const Color(
                                                            0xFF64748B,
                                                          ),
                                                  ),
                                                ),
                                                Text(
                                                  ' • ',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: isDark
                                                        ? const Color(
                                                            0xFF475569,
                                                          )
                                                        : const Color(
                                                            0xFFCBD5E1,
                                                          ),
                                                  ),
                                                ),
                                              ],
                                              Text(
                                                item.sellPrice.toCurrency(),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: isDark
                                                      ? const Color(0xFF94A3B8)
                                                      : const Color(0xFF64748B),
                                                ),
                                              ),
                                              Text(
                                                ' • Sold: ${item.quantity}',
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

                                    // Returnable Availability Status
                                    if (isItemReturnable)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7.5,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF10B981,
                                          ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          '${item.returnableQuantity} Avail',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF1E293B)
                                              : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'Returned',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: isDark
                                                ? const Color(0xFF64748B)
                                                : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (!isLast)
                                Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  color: borderColor.withValues(alpha: 0.4),
                                ),
                            ],
                          );
                        }),

                        const SizedBox(height: 12),

                        // Full Invoice Return Button
                        AppGradientButton(
                          onPressed: onProceedToReturn,
                          label: 'Proceed to Return',
                          height: 38,
                          borderRadius: 8,
                          fontSize: 12.5,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}
