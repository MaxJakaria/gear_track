import 'package:flutter/material.dart';
import 'package:gear_track/core/theme/app_colors.dart';
import 'package:gear_track/feature/database_maintenance/data/models/database_metrics.dart';

/// Ultra-minimal live cloud database status card matching GearTrack's luxury system
class DatabaseOverviewCard extends StatelessWidget {
  final DatabaseMetrics metrics;
  final bool isLoading;
  final VoidCallback onRefresh;

  const DatabaseOverviewCard({
    super.key,
    required this.metrics,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final innerBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Cloud Live Status & Refresh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.cloud_done_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cloud Database',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 5, color: Color(0xFF10B981)),
                        SizedBox(width: 4),
                        Text(
                          'Live',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: isLoading ? null : onRefresh,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 1.8),
                        )
                      : Icon(
                          Icons.refresh_rounded,
                          size: 16,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),

          // Compact Metric Pill Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: innerBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    label: 'Catalog',
                    value: '${metrics.productsCount}',
                    detail:
                        '${metrics.batchesCount} ${metrics.batchesCount == 1 ? 'batch' : 'batches'}',
                    accentColor: const Color(0xFF3B82F6),
                    isDark: isDark,
                  ),
                ),
                _buildVerticalDivider(isDark),
                Expanded(
                  child: _buildMetricItem(
                    label: 'Sales',
                    value: '${metrics.salesCount}',
                    detail:
                        '${metrics.invoicesCount} ${metrics.invoicesCount == 1 ? 'invoice' : 'invoices'}',
                    accentColor: const Color(0xFF10B981),
                    isDark: isDark,
                  ),
                ),
                _buildVerticalDivider(isDark),
                Expanded(
                  child: _buildMetricItem(
                    label: 'Returns',
                    value: '${metrics.returnsCount}',
                    detail:
                        metrics.returnsCount == 1 ? 'refund' : 'refunds',
                    accentColor: const Color(0xFFF59E0B),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider(bool isDark) {
    return Container(
      width: 0.8,
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required String detail,
    required Color accentColor,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          detail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}
