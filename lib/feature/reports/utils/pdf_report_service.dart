import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:gear_track/core/entities/shop_settings.dart';
import 'package:gear_track/feature/point_of_sale/utils/pdf_receipt_service.dart';
import 'package:gear_track/feature/reports/domain/entities/analytics_report.dart';

class PdfReportService {
  // Static font cache to prevent reloading font assets on every PDF generation
  static pw.Font? _cachedRegularFont;
  static pw.Font? _cachedBoldFont;

  static Future<void> _ensureFontsLoaded() async {
    if (_cachedRegularFont != null && _cachedBoldFont != null) return;
    try {
      final regularData = await rootBundle.load(
        'assets/fonts/pdf_font_regular.ttf',
      );
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
    final printDateStr = DateFormat('dd-MM-yyyy').format(now);

    final shopName = shopSettings.shopName.trim().isNotEmpty
        ? shopSettings.shopName.trim()
        : 'GearTrack Business Report';

    final shopAddress = shopSettings.address.trim();
    final shopPhone = shopSettings.phone.trim();

    final String periodLabel;
    if (startDate != null && endDate != null) {
      final df = DateFormat('dd-MM-yyyy');
      final startStr = df.format(startDate);
      final endStr = df.format(endDate);
      if (startStr == endStr) {
        periodLabel = startStr;
      } else {
        periodLabel = '$startStr to $endStr';
      }
    } else if (startDate != null) {
      periodLabel = DateFormat('dd-MM-yyyy').format(startDate);
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
    // [SL., INVOICE, PRODUCT NAME, PART NO, QTY, UNIT PRICE, TOTAL PRICE]
    final List<List<String>> preformattedRows = [];
    int invoiceSl = 0;

    for (int i = 0; i < sales.length; i++) {
      final s = sales[i];
      final bool isSameInvoice = i > 0 &&
          s.invoiceId.isNotEmpty &&
          s.invoiceId == sales[i - 1].invoiceId;

      if (!isSameInvoice) {
        invoiceSl++;
      }

      final totalPrice = s.itemsSold * s.sellPrice;
      final itemAndModel = s.model.isNotEmpty
          ? '${s.itemName}\n(${s.model})'
          : s.itemName;

      preformattedRows.add([
        isSameInvoice ? '' : '$invoiceSl',
        isSameInvoice ? '' : (s.invoiceId.isNotEmpty ? s.invoiceId : '-'),
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
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(
                fontSize: 7.5,
                color: PdfColors.grey700,
              ),
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

          // 2. Executive Summary Table
          widgets.add(
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
              ),
              headerHeight: 20,
              cellHeight: 20,
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              headerStyle: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey900,
              ),
              cellStyle: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey900,
              ),
              cellAlignments: {
                if (!isFilterApplied) ...{
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                } else ...{
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                },
              },
              headers: [
                if (!isFilterApplied) 'Total Investment',
                'Total Revenue',
                'Total Profit',
              ],
              data: [
                [
                  if (!isFilterApplied) formatCurrency(summary.totalInvestment),
                  formatCurrency(summary.totalSales),
                  formatCurrency(summary.totalProfit),
                ],
              ],
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
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
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
                  0: pw.FixedColumnWidth(28), // Sl.
                  1: pw.FixedColumnWidth(80), // Invoice
                  2: pw.FlexColumnWidth(2.0), // Product Name
                  3: pw.FixedColumnWidth(80), // Part No
                  4: pw.FixedColumnWidth(35), // Qty
                  5: pw.FixedColumnWidth(65), // Unit Price
                  6: pw.FixedColumnWidth(70), // Total Price
                },
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.center,
                  5: pw.Alignment.center,
                  6: pw.Alignment.centerRight,
                },
                headers: [
                  'Sl.',
                  'Invoice',
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

  /// Builds a descriptive filename for the exported PDF report.
  static String buildReportFileName({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (startDate != null && endDate != null) {
      final start = DateFormat('yyyyMMdd').format(startDate);
      final end = DateFormat('yyyyMMdd').format(endDate);
      return 'geartrack_report_${start}_$end.pdf';
    } else if (startDate != null) {
      final start = DateFormat('yyyyMMdd').format(startDate);
      return 'geartrack_report_$start.pdf';
    } else {
      final nowStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      return 'geartrack_all_time_report_$nowStr.pdf';
    }
  }

  /// Writes the generated PDF report bytes to the device's default Download storage.
  static Future<File> saveReportToDevice({
    required Uint8List pdfBytes,
    required String fileName,
    Directory? customDirectory,
  }) async {
    if (customDirectory != null) {
      if (!await customDirectory.exists()) {
        await customDirectory.create(recursive: true);
      }
      final file = File(
        '${customDirectory.path}${Platform.pathSeparator}$fileName',
      );
      await file.writeAsBytes(pdfBytes, flush: true);
      return file;
    }

    final candidates = await PdfReceiptService.getCandidateDownloadDirectories();
    for (final dir in candidates) {
      try {
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        final file = File('${dir.path}${Platform.pathSeparator}$fileName');
        await file.writeAsBytes(pdfBytes, flush: true);
        return file;
      } catch (_) {
        // Try next candidate directory
      }
    }

    final fallbackDir = await getApplicationDocumentsDirectory();
    final file = File('${fallbackDir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(pdfBytes, flush: true);
    return file;
  }
}
