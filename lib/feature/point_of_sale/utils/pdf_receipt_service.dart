import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
      final fonts = await Future.wait([
        PdfGoogleFonts.notoSansBengaliRegular(),
        PdfGoogleFonts.notoSansBengaliBold(),
      ]).timeout(const Duration(seconds: 3));
      _cachedBanglaFont = fonts[0];
      _cachedBanglaFontBold = fonts[1];
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
        margin: const pw.EdgeInsets.all(12),
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
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        if (displayedAddress.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          pw.Text(
                            displayedAddress,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ],
                        if (displayedPhone.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Phone: $displayedPhone',
                            style: const pw.TextStyle(fontSize: 8.5),
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: qrPayload, // Encodes ID, Date, Time & Total
                    width: 44,
                    height: 44,
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // Meta Info: ID, Date & Time
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    invoiceId,
                    style: pw.TextStyle(
                      fontSize: 7.2,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '$dateStr $timeStr',
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),

              // Items Table - Consolidated by Product (3 Columns: Item Name, Qty & Rate, Total)
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Item Name', 'Qty & Rate', 'Total'],
                  ...groupedItems.entries.map((entry) {
                    final productName = entry.key;
                    final batches = entry.value;

                    final title = productName.length > 22
                        ? '${productName.substring(0, 21)}.'
                        : productName;

                    // Formats: "qty × rate\nqty × rate" -> e.g. "2×100\n1×120"
                    final qtyRateBreakdown = batches
                        .map((b) {
                          final priceStr = b.sellPrice % 1 == 0
                              ? b.sellPrice.toInt().toString()
                              : b.sellPrice.toString();
                          return '${b.quantity}×$priceStr';
                        })
                        .join('\n');

                    final subtotal = batches.fold(
                      0.0,
                      (sum, b) => sum + b.subtotal,
                    );

                    return [title, qtyRateBreakdown, subtotal.toCurrency()];
                  }),
                ],
                border: pw.TableBorder.all(width: 0.2),
                headerStyle: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                headerAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                },
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                },
                columnWidths: {
                  0: const pw.FlexColumnWidth(4.5),
                  1: const pw.FlexColumnWidth(3.0),
                  2: const pw.FlexColumnWidth(2.5),
                },
              ),
              pw.SizedBox(height: 10),

              // Total Row aligned with Table columns
              pw.Row(
                children: [
                  pw.Expanded(flex: 45, child: pw.SizedBox()),
                  pw.Expanded(
                    flex: 30,
                    child: pw.Text(
                      'Total :',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 25,
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.only(right: 2),
                      child: pw.Text(
                        totalAmount.toCurrency(),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Footer
              pw.Center(
                child: pw.Text(
                  'May Allah put Barakah in your purchase.',
                  style: pw.TextStyle(fontSize: 8),
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
