import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          final sStr = fmt.format(startDate!);
          final eStr = fmt.format(endDate!);
          if (sStr == eStr && startDate!.year == endDate!.year) {
            return "Sales ($sStr)";
          }
          return "Sales ($sStr - $eStr)";
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

    // Precompute invoice grouping and serial numbers
    final List<_InvoiceGroup> invoiceGroups = [];
    int currentInvoiceSl = 0;

    for (final r in displayedRecords) {
      if (invoiceGroups.isNotEmpty &&
          r.invoiceId.isNotEmpty &&
          invoiceGroups.last.invoiceId == r.invoiceId) {
        invoiceGroups.last.items.add(r);
      } else {
        currentInvoiceSl++;
        invoiceGroups.add(
          _InvoiceGroup(
            slNumber: currentInvoiceSl,
            invoiceId: r.invoiceId,
            partyName: r.partyName,
            items: [r],
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Title & Records Count Badge (No outer card)
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0, top: 4.0),
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
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '${displayedRecords.length} records',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Horizontally scrollable table container allowing full text display on all screen sizes
        LayoutBuilder(
          builder: (context, constraints) {
            const double minTableWidth = 610.0;
            final double tableWidth = constraints.maxWidth > minTableWidth
                ? constraints.maxWidth
                : minTableWidth;

            final gridBorderColor = isDark
                ? const Color(0xFF475569) // Deep slate divider in dark mode
                : const Color(0xFFCBD5E1); // Deep crisp divider in light mode

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Container(
                width: tableWidth,
                decoration: BoxDecoration(
                  border: Border.all(color: gridBorderColor, width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Table Column Headers with vertical column dividers
                    IntrinsicHeight(
                      child: Container(
                        decoration: BoxDecoration(
                          color: headerBg,
                          border: Border(
                            bottom: BorderSide(
                              color: gridBorderColor,
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: 32,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                  vertical: 8.0,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: gridBorderColor,
                                      width: 0.8,
                                    ),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Sl.',
                                  textAlign: TextAlign.center,
                                  style: headerTextStyle,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 118,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                  vertical: 8.0,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: gridBorderColor,
                                      width: 0.8,
                                    ),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Invoice',
                                  textAlign: TextAlign.center,
                                  style: headerTextStyle,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 8.0,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: gridBorderColor,
                                      width: 0.8,
                                    ),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Product\nName',
                                  textAlign: TextAlign.center,
                                  style: headerTextStyle,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                  vertical: 8.0,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: gridBorderColor,
                                      width: 0.8,
                                    ),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Part\nNo.',
                                  textAlign: TextAlign.center,
                                  style: headerTextStyle,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2.0,
                                  vertical: 8.0,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: gridBorderColor,
                                      width: 0.8,
                                    ),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Qty',
                                  textAlign: TextAlign.center,
                                  style: headerTextStyle,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 72,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                  vertical: 8.0,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: gridBorderColor,
                                      width: 0.8,
                                    ),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Unit\nPrice',
                                  textAlign: TextAlign.center,
                                  style: headerTextStyle,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 68,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3.0,
                                  vertical: 8.0,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Total\nPrice',
                                  textAlign: TextAlign.center,
                                  style: headerTextStyle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Table Content / Empty State
                    if (displayedRecords.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36.0),
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
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: invoiceGroups.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          thickness: 1.0,
                          color: gridBorderColor,
                        ),
                        itemBuilder: (context, index) {
                          final group = invoiceGroups[index];

                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // SL. (Unified across all items in invoice, vertically centered)
                                SizedBox(
                                  width: 32,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0,
                                      vertical: 9.0,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        right: BorderSide(
                                          color: gridBorderColor,
                                          width: 0.8,
                                        ),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${group.slNumber}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ),

                                // Invoice (Unified across all items in invoice, vertically centered, tap to copy)
                                SizedBox(
                                  width: 118,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        right: BorderSide(
                                          color: gridBorderColor,
                                          width: 0.8,
                                        ),
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: group.invoiceId.isNotEmpty
                                            ? () {
                                                Clipboard.setData(
                                                  ClipboardData(
                                                    text: group.invoiceId,
                                                  ),
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).hideCurrentSnackBar();
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .check_circle_outline,
                                                          color: Colors.white,
                                                          size: 16,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            'Invoice "${group.invoiceId}" copied',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    duration: const Duration(
                                                      milliseconds: 1200,
                                                    ),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                  ),
                                                );
                                              }
                                            : null,
                                        child: Container(
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4.0,
                                            vertical: 6.0,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      group.invoiceId.isNotEmpty
                                                          ? group.invoiceId
                                                          : '-',
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 10.0,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: isDark
                                                            ? const Color(
                                                                0xFFE2E8F0,
                                                              )
                                                            : const Color(
                                                                0xFF1E293B,
                                                              ),
                                                      ),
                                                    ),
                                                  ),
                                                  if (group
                                                      .invoiceId
                                                      .isNotEmpty) ...[
                                                    const SizedBox(width: 3),
                                                    Icon(
                                                      Icons.copy_rounded,
                                                      size: 11,
                                                      color: isDark
                                                          ? const Color(
                                                              0xFF64748B,
                                                            )
                                                          : const Color(
                                                              0xFF94A3B8,
                                                            ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              if (group.partyName.trim().isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  group.partyName.trim(),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 9.0,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark
                                                        ? const Color(
                                                            0xFF38BDF8,
                                                          )
                                                        : const Color(
                                                            0xFF0284C7,
                                                          ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Item Rows (Divided only among items of this invoice)
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      for (
                                        int i = 0;
                                        i < group.items.length;
                                        i++
                                      ) ...[
                                        if (i > 0)
                                          Divider(
                                            height: 1,
                                            thickness: 0.8,
                                            color: gridBorderColor,
                                          ),
                                        _buildItemRow(
                                          group.items[i],
                                          gridBorderColor,
                                          isDark,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildItemRow(
    SalesRecordDetail record,
    Color gridBorderColor,
    bool isDark,
  ) {
    final double totalPrice = record.sellPrice * record.itemsSold;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Product Name (Full text displayed)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 9.0,
              ),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: gridBorderColor, width: 0.8),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                record.itemName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ),

          // Part No (Full text displayed)
          SizedBox(
            width: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 4.0,
                vertical: 9.0,
              ),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: gridBorderColor, width: 0.8),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                record.partNo.isNotEmpty ? record.partNo : '-',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF334155),
                ),
              ),
            ),
          ),

          // Qty Badge
          SizedBox(
            width: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 2.0,
                vertical: 9.0,
              ),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: gridBorderColor, width: 0.8),
                ),
              ),
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      (isDark
                              ? const Color(0xFF6366F1)
                              : const Color(0xFF4F46E5))
                          .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${record.itemsSold}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFF818CF8)
                        : const Color(0xFF4F46E5),
                  ),
                ),
              ),
            ),
          ),

          // Unit Price Column (Full text displayed)
          SizedBox(
            width: 72,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 4.0,
                vertical: 9.0,
              ),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: gridBorderColor, width: 0.8),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _formatPrice(record.sellPrice),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF334155),
                ),
              ),
            ),
          ),

          // Total Price Column (Full text displayed)
          SizedBox(
            width: 68,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 3.0,
                vertical: 9.0,
              ),
              alignment: Alignment.center,
              child: Text(
                _formatPrice(totalPrice),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFF34D399)
                      : const Color(0xFF059669), // Emerald
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceGroup {
  final int slNumber;
  final String invoiceId;
  final String partyName;
  final List<SalesRecordDetail> items;

  _InvoiceGroup({
    required this.slNumber,
    required this.invoiceId,
    this.partyName = '',
    required this.items,
  });
}
