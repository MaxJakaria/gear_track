import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:gear_track/feature/product_of_sales/domain/entities/cart_item.dart';
import 'package:gear_track/core/utils/currency_formatter.dart';

class PdfReceiptService {
  static Future<pw.Document> generateReceipt(
    List<CartItem> items,
    double totalAmount,
  ) async {
    final pdf = pw.Document();

    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final invoiceId =
        'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';

    final banglaFont = await PdfGoogleFonts.notoSansBengaliRegular();
    final banglaFontBold = await PdfGoogleFonts.notoSansBengaliBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Thermal 80mm
        orientation: pw.PageOrientation.portrait,
        margin: const pw.EdgeInsets.all(12),
        theme: pw.ThemeData.withFont(base: banglaFont, bold: banglaFontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              // Header & QR Code Row
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'GearTrack POS',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '123 Gear Street, Auto City',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: invoiceId, // Sale ID
                    width: 40,
                    height: 40,
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // Meta Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Invoice: $invoiceId',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(dateStr, style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.SizedBox(height: 6),

              // Items Table
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Item', 'Count', 'Price', 'Total'],
                  ...items.map((item) {
                    // Ensure item title stays on a single line by truncating
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
                ), // Table borders restored
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
                  ), // Matches 'Item' (4) + 'Count' (2)
                  pw.Expanded(
                    flex: 18, // Matches 'Price' (1.8)
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
                    flex: 22, // Matches 'Total' (2.2)
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
              pw.SizedBox(height: 12),

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
