import 'package:flutter/material.dart';
import 'package:gear_track/core/utils/currency_formatter.dart';

class ReturnSummaryCard extends StatelessWidget {
  final int totalReturnQuantity;
  final double totalRefundAmount;
  final int restockedCount;
  final int nonRestockedCount;
  final bool isProcessing;
  final VoidCallback onConfirmReturn;

  const ReturnSummaryCard({
    super.key,
    required this.totalReturnQuantity,
    required this.totalRefundAmount,
    required this.restockedCount,
    required this.nonRestockedCount,
    required this.isProcessing,
    required this.onConfirmReturn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canSubmit = totalReturnQuantity > 0 && !isProcessing;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'REFUND SUMMARY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE11D48).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$totalReturnQuantity Items Selected',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE11D48),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Total Refund Big Banner
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Total Refund Amount',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              Text(
                totalRefundAmount.toCurrency(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFE11D48),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Restock stats
          Row(
            children: [
              Icon(
                Icons.restore_from_trash_rounded,
                size: 14,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                '$restockedCount to inventory  •  $nonRestockedCount damaged/discarded',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Confirm Button
          ElevatedButton(
            onPressed: canSubmit ? onConfirmReturn : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              disabledBackgroundColor: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
              disabledForegroundColor: isDark
                  ? const Color(0xFF64748B)
                  : const Color(0xFF94A3B8),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: canSubmit ? 3 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_return_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Confirm Return & Issue Refund',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
