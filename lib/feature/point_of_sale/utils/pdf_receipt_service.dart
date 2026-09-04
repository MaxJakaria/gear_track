import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:gear_track/core/entities/shop_settings.dart';
import 'package:gear_track/feature/point_of_sale/domain/entities/cart_item.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';
import 'package:gear_track/core/utils/currency_formatter.dart';

class PdfReceiptService {
  static pw.Font? _cachedBanglaFont;
  static pw.Font? _cachedBanglaFontBold;

  static Future<void> _ensureFontsLoaded() async {
    if (_cachedBanglaFont != null && _cachedBanglaFontBold != null) return;
    try {
      final regularData = await rootBundle.load('assets/fonts/pdf_font_regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/pdf_font_bold.ttf');
      _cachedBanglaFont = pw.Font.ttf(regularData);
      _cachedBanglaFontBold = pw.Font.ttf(boldData);
    } catch (_) {
      _cachedBanglaFont ??= pw.Font.helvetica();
      _cachedBanglaFontBold ??= pw.Font.helveticaBold();
    }
  }

  static Future<pw.Document> generateReceipt(
    List<CartItem> items,
    double totalAmount, {
    ShopSettings shopSettings = const ShopSettings(),
    InvoiceEntity? invoice,
  }) async {
    final pdf = pw.Document();

    final now = invoice?.saleDate ?? DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final invoiceId =
        invoice?.invoiceId ??
        'INV-POS01-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-0001';

    // QR Data containing unique ID, Date, Time & Total Amount
    final qrPayload =
        invoice?.qrPayload ??
        'GT-RECEIPT|ID:$invoiceId|DATE:$dateStr|TIME:$timeStr|TOTAL:${totalAmount.toStringAsFixed(2)}';

    await _ensureFontsLoaded();
    final banglaFont = _cachedBanglaFont ?? pw.Font.helvetica();
    final banglaFontBold = _cachedBanglaFontBold ?? pw.Font.helveticaBold();

    final displayedShopName = shopSettings.shopName.trim().isNotEmpty
        ? shopSettings.shopName.trim()
        : (invoice?.shopName.trim().isNotEmpty == true
              ? invoice!.shopName.trim()
              : '');

    final displayedAddress = shopSettings.address.trim().isNotEmpty
        ? shopSettings.address.trim()
        : (invoice?.shopAddress.trim() ?? '');

    final displayedPhone = shopSettings.phone.trim().isNotEmpty
        ? shopSettings.phone.trim()
        : (invoice?.shopPhone.trim() ?? '');

    // Group cart items by product name so same product with different batches appears in 1 consolidated row
    final Map<String, List<CartItem>> groupedItems = {};
    for (final item in items) {
      final key = item.itemName.trim();
      groupedItems.putIfAbsent(key, () => []).add(item);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Thermal 80mm
        orientation: pw.PageOrientation.portrait,
        margin: const pw.EdgeInsets.all(8),
        theme: pw.ThemeData.withFont(base: banglaFont, bold: banglaFontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header & QR Code Row
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (displayedShopName.isNotEmpty)
                          pw.Text(
                            displayedShopName,
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        if (displayedAddress.isNotEmpty) ...[
                          pw.SizedBox(height: 1),
                          pw.Text(
                            displayedAddress,
                            style: const pw.TextStyle(fontSize: 5.0),
                          ),
                        ],
                        if (displayedPhone.isNotEmpty) ...[
                          pw.SizedBox(height: 0.8),
                          pw.Text(
                            'Phone: $displayedPhone',
                            style: const pw.TextStyle(fontSize: 5.0),
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 4),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: qrPayload, // Encodes ID, Date, Time & Total
                    width: 24,
                    height: 24,
                  ),
                ],
              ),
              pw.SizedBox(height: 4),

              // Meta Info: ID, Date & Time
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    invoiceId,
                    style: pw.TextStyle(
                      fontSize: 4.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '$dateStr $timeStr',
                    style: const pw.TextStyle(fontSize: 4.2),
                  ),
                ],
              ),
              pw.SizedBox(height: 2.5),

              // Items Table (6 Columns: Sl., Product Name, Part No, Qty, Unit Price, Total Price)
              pw.TableHelper.fromTextArray(
                context: context,
                headers: <String>[
                  'Sl.',
                  'Product Name',
                  'Part No',
                  'Qty',
                  'Unit Price',
                  'Total Price',
                ],
                data: <List<String>>[
                  for (int i = 0; i < items.length; i++)
                    [
                      '${i + 1}',
                      items[i].itemName,
                      items[i].partNo.isNotEmpty ? items[i].partNo : '-',
                      '${items[i].quantity} PCS',
                      items[i].sellPrice.toCurrency(),
                      items[i].subtotal.toCurrency(),
                    ],
                ],
                border: pw.TableBorder.all(width: 0.25, color: PdfColors.grey500),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                headerStyle: pw.TextStyle(
                  fontSize: 4.0,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: const pw.TextStyle(fontSize: 3.8),
                headerAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                  4: pw.Alignment.center,
                  5: pw.Alignment.center,
                },
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                  4: pw.Alignment.center,
                  5: pw.Alignment.center,
                },
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.7), // Sl.
                  1: const pw.FlexColumnWidth(3.2), // Product Name
                  2: const pw.FlexColumnWidth(1.9), // Part No
                  3: const pw.FlexColumnWidth(1.1), // Qty
                  4: const pw.FlexColumnWidth(1.6), // Unit Price
                  5: const pw.FlexColumnWidth(1.8), // Total Price
                },
                cellPadding:
                    const pw.EdgeInsets.symmetric(horizontal: 0.8, vertical: 1.2),
                headerPadding:
                    const pw.EdgeInsets.symmetric(horizontal: 0.8, vertical: 2.0),
              ),
              pw.SizedBox(height: 4),

              // Total Row
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total : ',
                    style: pw.TextStyle(
                      fontSize: 5.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    totalAmount.toCurrency(),
                    style: pw.TextStyle(
                      fontSize: 5.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),

              // Footer
              pw.Center(
                child: pw.Text(
                  'May Allah put Barakah in your purchase.',
                  style: const pw.TextStyle(fontSize: 4.5),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }
}
