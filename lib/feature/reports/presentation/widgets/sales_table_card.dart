import 'package:flutter/material.dart';
import 'package:gear_track/core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/report_period.dart';
import '../../domain/entities/sales_record_detail.dart';

class SalesTableCard extends StatelessWidget {
  final List<SalesRecordDetail> salesRecords;
  final ReportPeriod period;
  final DateTime? startDate;
  final DateTime? endDate;
  final String currencySymbol;

  const SalesTableCard({
    super.key,
    required this.salesRecords,
    required this.period,
    this.startDate,
    this.endDate,
    this.currencySymbol = '৳',
  });

  String get _title {
    switch (period) {
      case ReportPeriod.today:
        return "Today's Sales";
      case ReportPeriod.thisMonth:
        return "This Month's Sales";
      case ReportPeriod.trends:
        return "Recent Sales";
      case ReportPeriod.custom:
        if (startDate != null && endDate != null) {
          final fmt = DateFormat('MMM d');
          return "Sales (${fmt.format(startDate!)} - ${fmt.format(endDate!)})";
        }
        return "Custom Range Sales";
    }
  }

  String get _emptyMessage {
    switch (period) {
      case ReportPeriod.today:
        return "No sales recorded for today";
      case ReportPeriod.thisMonth:
        return "No sales recorded for this month";
      case ReportPeriod.trends:
        return "No sales records found";
      case ReportPeriod.custom:
        return "No sales found for selected date range";
    }
  }

  String _formatPrice(double price) {
    if (price % 1 == 0) {
      return '$currencySymbol${price.toInt()}';
    }
    return '$currencySymbol${price.toStringAsFixed(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = AppColors.primaryButton(context);

    final headerBg = isDark
        ? AppColors.surfaceContainerDark
        : AppColors.surfaceContainerLight;

    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final headerTextStyle = TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
    );

    // When a custom date range is selected, show ALL sales in that range.
    // In general/all-time overview, show the latest 20 sales.
    final bool isCustomRange =
        period == ReportPeriod.custom || (startDate != null && endDate != null);
    final displayedRecords = isCustomRange
        ? salesRecords
        : salesRecords.take(20).toList();

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Title Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.table_chart_outlined,
                      size: 18,
                      color: primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: primaryBlue.withValues(alpha: isDark ? 0.20 : 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${displayedRecords.length} records',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFF818CF8)
                          : const Color(0xFF4F46E5),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 1, color: borderColor.withValues(alpha: 0.6)),

          // Table Column Headers
          Container(
            color: headerBg,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text('DATE', style: headerTextStyle),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 54,
                  child: Text('PART NO', style: headerTextStyle),
                ),
                const SizedBox(width: 6),
                Expanded(child: Text('ITEM / MODEL', style: headerTextStyle)),
                const SizedBox(width: 6),
                SizedBox(
                  width: 36,
                  child: Text(
                    'SOLD',
                    textAlign: TextAlign.center,
                    style: headerTextStyle,
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 58,
                  child: Text(
                    'PRICE',
                    textAlign: TextAlign.right,
                    style: headerTextStyle,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // Table Content / Empty State
          if (displayedRecords.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 36.0,
                horizontal: 16.0,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 36,
                      color: isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFFCBD5E1),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _emptyMessage,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayedRecords.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, thickness: 0.5),
              itemBuilder: (context, index) {
                final record = displayedRecords[index];
                final dateStr = DateFormat('MM-dd').format(record.saleDate);
                final double totalPrice = record.sellPrice * record.itemsSold;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10.0,
                  ),
                  child: Row(
                    children: [
                      // Date
                      SizedBox(
                        width: 44,
                        child: Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Part No
                      SizedBox(
                        width: 54,
                        child: Text(
                          record.partNo.isNotEmpty ? record.partNo : '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF334155),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Item Name + Model (Two-line compact layout)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              record.itemName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            if (record.model.isNotEmpty) ...[
                              const SizedBox(height: 1),
                              Text(
                                record.model,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Items Sold Badge (Placed BEFORE Total Price)
                      SizedBox(
                        width: 36,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (isDark
                                        ? const Color(0xFF6366F1)
                                        : const Color(0xFF4F46E5))
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${record.itemsSold}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFF818CF8)
                                  : const Color(0xFF4F46E5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Total Price Column (Placed AFTER SOLD)
                      SizedBox(
                        width: 58,
                        child: Text(
                          _formatPrice(totalPrice),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFF34D399)
                                : const Color(0xFF059669), // Emerald
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
