import 'package:flutter/material.dart';
import 'package:gear_track/core/theme/app_colors.dart';

/// Ultra-minimal single-row Danger Zone component
class DangerZoneCard extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onWipeDatabase;

  const DangerZoneCard({
    super.key,
    required this.isProcessing,
    required this.onWipeDatabase,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const dangerRed = Color(0xFFEF4444);
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.14)
                : const Color(0xFF64748B).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: dangerRed.withValues(alpha: isDark ? 0.16 : 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: dangerRed,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Factory Reset',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: dangerRed,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Full wipe back to day one',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
          const SizedBox(width: 8),
          InkWell(
            onTap: isProcessing ? null : onWipeDatabase,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4.5,
              ),
              decoration: BoxDecoration(
                color: isProcessing
                    ? (isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0))
                    : dangerRed.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isProcessing
                  ? const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        valueColor: AlwaysStoppedAnimation<Color>(dangerRed),
                      ),
                    )
                  : const Text(
                      'Reset All',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.1,
                        color: dangerRed,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
