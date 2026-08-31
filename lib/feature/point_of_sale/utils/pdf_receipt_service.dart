import 'dart:math';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:gear_track/core/entities/shop_settings.dart';
import 'package:gear_track/feature/point_of_sale/domain/entities/cart_item.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';
import 'package:gear_track/core/utils/currency_formatter.dart';

class PdfReceiptService {
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
    final invoiceId = invoice?.invoiceId ??
        'GT-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${(Random().nextInt(900000) + 100000)}';

    // QR Data containing unique ID, Date, Time & Total Amount
    final qrPayload = invoice?.qrPayload ??
        'GT-RECEIPT|ID:$invoiceId|DATE:$dateStr|TIME:$timeStr|TOTAL:${totalAmount.toStringAsFixed(2)}';

    final banglaFont = await PdfGoogleFonts.notoSansBengaliRegular();
    final banglaFontBold = await PdfGoogleFonts.notoSansBengaliBold();

    final displayedShopName = shopSettings.shopName.trim().isNotEmpty
        ? shopSettings.shopName.trim()
        : (invoice?.shopName.trim().isNotEmpty == true
            ? invoice!.shopName.trim()
            : 'GearTrack POS');

    final displayedAddress = shopSettings.address.trim().isNotEmpty
        ? shopSettings.address.trim()
        : (invoice?.shopAddress.trim() ?? '');

    final displayedPhone = shopSettings.phone.trim().isNotEmpty
        ? shopSettings.phone.trim()
        : (invoice?.shopPhone.trim() ?? '');

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

              // Meta Info: Invoice, Date & Time
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Invoice: $invoiceId',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '$dateStr $timeStr',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),

              // Items Table
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Item', 'Count', 'Price', 'Total'],
                  ...items.map((item) {
                    final title = item.itemName.length > 16
                        ? '${item.itemName.substring(0, 15)}.'
                        : item.itemName;
                    return [
                      title,
                      '${item.quantity}',
                      item.sellPrice.toCurrency(),
                      item.subtotal.toCurrency(),
                    ];
                  }),
                ],
                border: pw.TableBorder.all(
                  width: 0.2,
                ),
                headerStyle: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                headerAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                },
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                },
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(1.8),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2.2),
                },
              ),
              pw.SizedBox(height: 10),

              // Total Row aligned with Table columns
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 60,
                    child: pw.SizedBox(),
                  ),
                  pw.Expanded(
                    flex: 18,
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
                    flex: 22,
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
