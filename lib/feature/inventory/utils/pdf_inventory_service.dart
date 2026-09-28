import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:gear_track/core/entities/shop_settings.dart';
import 'package:gear_track/feature/inventory/domain/entities/grouped_product.dart';
import 'package:gear_track/feature/point_of_sale/utils/pdf_receipt_service.dart';

class PdfInventoryService {
  static pw.Font? _cachedRegularFont;
  static pw.Font? _cachedBoldFont;

  static const tableColumnWidths = {
    0: pw.FixedColumnWidth(26.0), // Sl.
    1: pw.FixedColumnWidth(215.0), // Item Name & Model
    2: pw.FixedColumnWidth(45.0), // Stock
    3: pw.FixedColumnWidth(
      257.28,
    ), // Batches (Part No 132.28 + Cost Code 80.0 + Qty 45.0)
  };

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

  /// Generates the printable inventory PDF document.
  static Future<Uint8List> generateInventoryPdf({
    required List<GroupedProduct> items,
    required ShopSettings shopSettings,
    required String filterTitle,
    required int totalStockUnits,
  }) async {
    await _ensureFontsLoaded();

    final regularFont = _cachedRegularFont ?? pw.Font.helvetica();
    final boldFont = _cachedBoldFont ?? pw.Font.helveticaBold();

    final pdf = pw.Document();
    final now = DateTime.now();
    final printDateStr = DateFormat('dd-MM-yyyy hh:mm a').format(now);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        maxPages: 300,
        margin: const pw.EdgeInsets.symmetric(horizontal: 26, vertical: 26),
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        footer: _buildFooter,
        build: (pw.Context context) {
          final List<pw.Widget> widgets = [];

          // 1. Header Section
          widgets.add(
            _buildHeader(
              shopSettings: shopSettings,
              filterTitle: filterTitle,
              printDateStr: printDateStr,
            ),
          );

          // 2. Stock Table
          if (items.isEmpty) {
            widgets.add(
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.symmetric(vertical: 24),
                child: pw.Text(
                  'No products found matching the criteria.',
                  style: const pw.TextStyle(
                    fontSize: 9.5,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            );
          } else {
            final List<pw.TableRow> tableRows = [
              _buildTableHeader(),
              for (int i = 0; i < items.length; i++)
                _buildItemRow(i + 1, items[i]),
            ];

            widgets.add(
              pw.Table(
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
                border: const pw.TableBorder(
                  top: pw.BorderSide(color: PdfColors.black, width: 0.5),
                  bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
                  left: pw.BorderSide(color: PdfColors.black, width: 0.5),
                  right: pw.BorderSide(color: PdfColors.black, width: 0.5),
                  horizontalInside: pw.BorderSide(
                    color: PdfColors.black,
                    width: 0.5,
                  ),
                  verticalInside: pw.BorderSide(
                    color: PdfColors.black,
                    width: 0.5,
                  ),
                ),
                columnWidths: tableColumnWidths,
                children: tableRows,
              ),
            );
          }

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  /// Builds top header with Shop details on left and Report metadata on right.
  static pw.Widget _buildHeader({
    required ShopSettings shopSettings,
    required String filterTitle,
    required String printDateStr,
  }) {
    final shopName = shopSettings.shopName.trim().isNotEmpty
        ? shopSettings.shopName.trim()
        : 'GearTrack Inventory Report';
    final shopAddress = shopSettings.address.trim();
    final shopPhone = shopSettings.phone.trim();
    final shopEmail = shopSettings.email.trim();

    return pw.Container(
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
                    fontSize: 13,
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
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
                if (shopPhone.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Phone: $shopPhone',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
                if (shopEmail.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Email: $shopEmail',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey800,
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
                'Inventory Stock Report',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo900,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Category: $filterTitle',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Printed on: $printDateStr',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the table column header row.
  static pw.TableRow _buildTableHeader() {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          child: pw.Text(
            'Sl.',
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey900,
            ),
          ),
        ),
        pw.Container(
          alignment: pw.Alignment.centerLeft,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Text(
            'Item Name & Model',
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey900,
            ),
          ),
        ),
        pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          child: pw.Text(
            'Stock',
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey900,
            ),
          ),
        ),
        pw.Row(
          children: [
            pw.Container(
              width: 132.28,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 5,
              ),
              alignment: pw.Alignment.centerLeft,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  right: pw.BorderSide(color: PdfColors.black, width: 0.5),
                ),
              ),
              child: pw.Text(
                'Part No',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),
            ),
            pw.Container(
              width: 80.0,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 5,
              ),
              alignment: pw.Alignment.center,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  right: pw.BorderSide(color: PdfColors.black, width: 0.5),
                ),
              ),
              child: pw.Text(
                'Cost Code',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),
            ),
            pw.Container(
              width: 45.0,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 5,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'Qty',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds a single item row spanning all its batch entries cleanly.
  static pw.TableRow _buildItemRow(int sl, GroupedProduct item) {
    final displayBatches = item.batches.isNotEmpty
        ? item.batches
              .map(
                (b) => (
                  partNo: b.partNo.isNotEmpty
                      ? b.partNo
                      : (item.partNo.isNotEmpty ? item.partNo : '-'),
                  costCode: b.costCode.isNotEmpty
                      ? b.costCode
                      : (item.latestCostCode.isNotEmpty
                            ? item.latestCostCode
                            : '-'),
                  stockCount: b.stockCount,
                ),
              )
              .toList()
        : [
            (
              partNo: item.partNo.isNotEmpty ? item.partNo : '-',
              costCode: item.latestCostCode.isNotEmpty
                  ? item.latestCostCode
                  : '-',
              stockCount: item.totalStockCount,
            ),
          ];

    final pw.Widget batchWidget = displayBatches.length == 1
        ? _buildBatchSubRow(
            partNo: displayBatches.first.partNo,
            costCode: displayBatches.first.costCode,
            stockCount: displayBatches.first.stockCount,
          )
        : pw.Column(
            children: [
              for (int i = 0; i < displayBatches.length; i++)
                _buildBatchSubRow(
                  partNo: displayBatches[i].partNo,
                  costCode: displayBatches[i].costCode,
                  stockCount: displayBatches[i].stockCount,
                  hasBottomDivider: i < displayBatches.length - 1,
                ),
            ],
          );

    return pw.TableRow(
      children: [
        // Col 0: Sl. (Centered vertically and horizontally)
        pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: pw.Text(
            '$sl',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey900),
          ),
        ),

        // Col 1: Item Name & Model (Left-Middle aligned)
        pw.Container(
          alignment: pw.Alignment.centerLeft,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4.5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                item.itemName,
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),
              if (item.model.isNotEmpty) ...[
                pw.SizedBox(height: 1.5),
                pw.Text(
                  'Model: ${item.model}',
                  style: const pw.TextStyle(
                    fontSize: 7.5,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Col 2: Total Stock (Centered vertically and horizontally)
        pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: pw.Text(
            '${item.totalStockCount}',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: item.totalStockCount <= 0
                  ? PdfColors.red700
                  : (item.totalStockCount <= 5
                        ? PdfColors.amber800
                        : PdfColors.grey900),
            ),
          ),
        ),

        // Col 3: Batches
        batchWidget,
      ],
    );
  }

  /// Reusable sub-row for a single batch (Part No | Cost Code | Stock Qty).
  static pw.Widget _buildBatchSubRow({
    required String partNo,
    required String costCode,
    required int stockCount,
    bool hasBottomDivider = false,
  }) {
    return pw.Container(
      decoration: hasBottomDivider
          ? const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
              ),
            )
          : null,
      child: pw.Row(
        children: [
          pw.Container(
            width: 132.28,
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 4.5,
            ),
            alignment: pw.Alignment.centerLeft,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                right: pw.BorderSide(color: PdfColors.black, width: 0.5),
              ),
            ),
            child: pw.Text(
              partNo,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey900),
            ),
          ),
          pw.Container(
            width: 80.0,
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 4.5,
            ),
            alignment: pw.Alignment.center,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                right: pw.BorderSide(color: PdfColors.black, width: 0.5),
              ),
            ),
            child: pw.Text(
              costCode,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey900),
            ),
          ),
          pw.Container(
            width: 45.0,
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 4.5,
            ),
            alignment: pw.Alignment.center,
            child: pw.Text(
              '$stockCount',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: stockCount <= 0
                    ? PdfColors.red700
                    : (stockCount <= 5
                          ? PdfColors.amber800
                          : PdfColors.grey900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds document footer with page numbers.
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
      ),
    );
  }

  /// Builds a clean descriptive file name for the downloaded PDF.
  static String buildInventoryFileName({required String filterName}) {
    final clean = filterName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final tag = clean.isNotEmpty ? clean : 'all_stock';
    return 'geartrack_inventory_${tag}_$dateStr.pdf';
  }

  /// Saves the generated PDF bytes to the device's Download storage.
  static Future<File> saveInventoryPdfToDevice({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    final candidates =
        await PdfReceiptService.getCandidateDownloadDirectories();
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
