import 'package:flutter/material.dart';
import 'package:gear_track/core/theme/app_colors.dart';
import 'package:gear_track/core/utils/currency_formatter.dart';
import 'package:gear_track/feature/returns/domain/entities/return_entity.dart';

/// Clean, minimal return history card matching GearTrack's luxury UI
class ReturnHistoryCard extends StatefulWidget {
  final ReturnEntity returnRecord;
  final Future<void> Function() onPrintVoucher;

  const ReturnHistoryCard({
    super.key,
    required this.returnRecord,
    required this.onPrintVoucher,
  });

  @override
  State<ReturnHistoryCard> createState() => _ReturnHistoryCardState();
}

class _ReturnHistoryCardState extends State<ReturnHistoryCard> {
  bool _isPrinting = false;

  Future<void> _handlePrint() async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);
    try {
      await widget.onPrintVoucher();
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final returnRecord = widget.returnRecord;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: ID, Invoice & Refund Amount
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon badge
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: (isDark ? const Color(0xFFF87171) : const Color(0xFFE11D48)).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.replay_rounded,
                      size: 16,
                      color: isDark ? const Color(0xFFF87171) : const Color(0xFFE11D48),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // IDs
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          returnRecord.returnId,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Inv: ${returnRecord.invoiceId}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        returnRecord.totalRefundAmount.toCurrency(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFF87171) : const Color(0xFFE11D48),
                        ),
                      ),
                      Text(
                        'Refunded',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Items summary text
              Text(
                '${returnRecord.totalQuantity} items: ${returnRecord.items.map((i) => '${i.quantity}x ${i.itemName}').join(', ')}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                ),
              ),

              const SizedBox(height: 8),
              Divider(height: 1, thickness: 0.6, color: borderColor),
              const SizedBox(height: 8),

              // Bottom Row: Date/Time + Print Voucher Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${returnRecord.formattedDate}  ${returnRecord.formattedTime}',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: _isPrinting ? null : _handlePrint,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          width: 0.6,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isPrinting) ...[
                            SizedBox(
                              width: 11,
                              height: 11,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                          ] else ...[
                            Icon(
                              Icons.receipt_long_rounded,
                              size: 12,
                              color: isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF475569),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            'Voucher',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
