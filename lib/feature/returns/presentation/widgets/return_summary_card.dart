import 'package:flutter/material.dart';
import 'package:gear_track/core/theme/app_colors.dart';
import 'package:gear_track/core/utils/currency_formatter.dart';
import 'package:gear_track/core/widgets/app_gradient_button.dart';

/// Minimalist, high-end return summary bar matching GearTrack's luxury UI
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
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Left: Total Refund & Items Count
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Total Refund',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      if (totalReturnQuantity > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.primaryButtonDark : AppColors.primaryButtonLight).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$totalReturnQuantity ${totalReturnQuantity == 1 ? 'item' : 'items'}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.primaryButtonDark : AppColors.primaryButtonLight,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    totalRefundAmount.toCurrency(),
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      color: isDark ? const Color(0xFFF87171) : const Color(0xFFE11D48),
                    ),
                  ),
                  if (totalReturnQuantity > 0) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (restockedCount > 0)
                          Text(
                            '$restockedCount Restock',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        if (restockedCount > 0 && nonRestockedCount > 0)
                          const Text(' • ', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                        if (nonRestockedCount > 0)
                          Text(
                            '$nonRestockedCount Damaged',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Right: Primary Action Button using project's AppGradientButton
            SizedBox(
              width: 115,
              height: 44,
              child: AppGradientButton(
                onPressed: canSubmit ? onConfirmReturn : null,
                label: 'Confirm',
                isLoading: isProcessing,
                height: 44,
                borderRadius: 8,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
