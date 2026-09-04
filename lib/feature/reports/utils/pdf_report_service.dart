import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:gear_track/core/entities/shop_settings.dart';
import 'package:gear_track/feature/reports/domain/entities/analytics_report.dart';

class PdfReportService {
  // Static font cache to prevent reloading font assets on every PDF generation
  static pw.Font? _cachedRegularFont;
  static pw.Font? _cachedBoldFont;

  static Future<void> _ensureFontsLoaded() async {
    if (_cachedRegularFont != null && _cachedBoldFont != null) return;
    try {
      final regularData = await rootBundle.load('assets/fonts/pdf_font_regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/pdf_font_bold.ttf');
      _cachedRegularFont = pw.Font.ttf(regularData);
      _cachedBoldFont = pw.Font.ttf(boldData);
    } catch (_) {
      _cachedRegularFont ??= pw.Font.helvetica();
      _cachedBoldFont ??= pw.Font.helveticaBold();
    }
  }

  static Future<Uint8List> generateReportPdf({
    required AnalyticsReport report,
    required ShopSettings shopSettings,
    DateTime? startDate,
    DateTime? endDate,
    bool isFilterApplied = false,
  }) async {
    await _ensureFontsLoaded();

    final regularFont = _cachedRegularFont ?? pw.Font.helvetica();
    final boldFont = _cachedBoldFont ?? pw.Font.helveticaBold();

    final pdf = pw.Document();

    final now = DateTime.now();
    final printDateStr = DateFormat('yyyy-MM-dd hh:mm a').format(now);

    final shopName = shopSettings.shopName.trim().isNotEmpty
        ? shopSettings.shopName.trim()
        : 'GearTrack Business Report';

    final shopAddress = shopSettings.address.trim();
    final shopPhone = shopSettings.phone.trim();

    final String periodLabel;
    if (startDate != null && endDate != null) {
      final df = DateFormat('dd MMM yyyy');
      periodLabel = '${df.format(startDate)} - ${df.format(endDate)}';
    } else if (startDate != null) {
      periodLabel = DateFormat('dd MMM yyyy').format(startDate);
    } else {
      periodLabel = 'All Time Overview';
    }

    String formatCurrency(double amount) {
      final formatter = NumberFormat.currency(
        locale: 'en_IN',
        symbol: '৳',
        decimalDigits: amount % 1 == 0 ? 0 : 1,
      );
      return formatter.format(amount);
    }

    final summary = report.summary;
    final sales = report.salesRecords;

    // Precompute formatted strings matching app sales table layout:
    // [SL., DATE, PRODUCT NAME, PART NO, QTY, UNIT PRICE, TOTAL PRICE]
    final dateFmt = DateFormat('yyyy-MM-dd');
    final List<List<String>> preformattedRows = [];
    for (int i = 0; i < sales.length; i++) {
      final s = sales[i];
      final totalPrice = s.itemsSold * s.sellPrice;
      final dateFormatted = dateFmt.format(s.saleDate);
      final itemAndModel = s.model.isNotEmpty
          ? '${s.itemName}\n(${s.model})'
          : s.itemName;

      preformattedRows.add([
        '${i + 1}',
        dateFormatted,
        itemAndModel,
        s.partNo.isNotEmpty ? s.partNo : '-',
        '${s.itemsSold} PCS',
        formatCurrency(s.sellPrice),
        formatCurrency(totalPrice),
      ]);
    }

    // Build the PDF Document
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        maxPages: 250,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'GearTrack Business Management • Generated securely',
                  style: const pw.TextStyle(
                    fontSize: 7.5,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(
                    fontSize: 7.5,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          final List<pw.Widget> widgets = [];

          // 1. Shop Info & Report Header (Displayed ONLY on 1st page)
          widgets.add(
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.only(bottom: 8),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.indigo400, width: 1.5),
                ),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          shopName,
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.indigo900,
                          ),
                        ),
                        if (shopAddress.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            shopAddress,
                            style: const pw.TextStyle(
                              fontSize: 8.5,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                        if (shopPhone.isNotEmpty) ...[
                          pw.SizedBox(height: 1.5),
                          pw.Text(
                            'Phone: $shopPhone',
                            style: const pw.TextStyle(
                              fontSize: 8.5,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Sales & Analytics Report',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Period: $periodLabel',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                      pw.SizedBox(height: 1.5),
                      pw.Text(
                        'Printed: $printDateStr',
                        style: const pw.TextStyle(
                          fontSize: 7.5,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );

          // 1. Executive Summary Title
          widgets.add(
            pw.Text(
              'Executive Summary',
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 4));

          // 2. Metrics Row (No background container)
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Row(
                children: [
                  if (!isFilterApplied) ...[
                    pw.Expanded(
                      child: _buildMetricBox(
                        'Total Investment',
                        formatCurrency(summary.totalInvestment),
                        PdfColors.indigo800,
                      ),
                    ),
                    pw.Container(
                      width: 1,
                      height: 26,
                      color: PdfColors.grey300,
                      margin: const pw.EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ],
                  pw.Expanded(
                    child: _buildMetricBox(
                      'Total Revenue',
                      formatCurrency(summary.totalSales),
                      PdfColors.blue800,
                    ),
                  ),
                  pw.Container(
                    width: 1,
                    height: 26,
                    color: PdfColors.grey300,
                    margin: const pw.EdgeInsets.symmetric(horizontal: 8),
                  ),
                  pw.Expanded(
                    child: _buildMetricBox(
                      'Total Profit',
                      formatCurrency(summary.totalProfit),
                      PdfColors.green800,
                    ),
                  ),
                ],
              ),
            ),
          );

          widgets.add(pw.SizedBox(height: 12));

          // 3. Transactions Header
          widgets.add(
            pw.Text(
              'Sales Transactions (${sales.length} records)',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 4));

          // 4. Sales Table (Single table matching app columns with repeatHeader: true on page change)
          if (sales.isEmpty) {
            widgets.add(
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'No sales transactions found for this period.',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            );
          } else {
            widgets.add(
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(
                  color: PdfColors.black,
                  width: 0.5,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                ),
                headerHeight: 22,
                cellHeight: 22,
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                headerStyle: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
                cellStyle: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey900,
                ),
                columnWidths: const {
                  0: pw.FixedColumnWidth(36), // Sl. (supports up to 5 digits e.g. 99999)
                  1: pw.FixedColumnWidth(56), // Date
                  2: pw.FlexColumnWidth(2.0), // Product Name
                  3: pw.FixedColumnWidth(88), // Part No
                  4: pw.FixedColumnWidth(44), // Qty
                  5: pw.FixedColumnWidth(65), // Unit Price
                  6: pw.FixedColumnWidth(70), // Total Price
                },
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.center,
                  5: pw.Alignment.center,
                  6: pw.Alignment.centerRight,
                },
                headers: [
                  'Sl.',
                  'Date',
                  'Product Name',
                  'Part No',
                  'Qty',
                  'Unit Price',
                  'Total Price',
                ],
                data: preformattedRows,
              ),
            );
          }

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildMetricBox(
    String title,
    String value,
    PdfColor valueColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          title,
          style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
          maxLines: 1,
        ),
        pw.SizedBox(height: 1.5),
        pw.FittedBox(
          fit: pw.BoxFit.scaleDown,
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
