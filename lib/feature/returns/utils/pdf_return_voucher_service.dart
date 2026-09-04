import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:gear_track/core/entities/shop_settings.dart';
import 'package:gear_track/feature/returns/domain/entities/return_entity.dart';
import 'package:gear_track/core/utils/currency_formatter.dart';

class PdfReturnVoucherService {
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

  static Future<pw.Document> generateReturnVoucher({
    required ReturnEntity returnRecord,
    ShopSettings shopSettings = const ShopSettings(),
  }) async {
    final pdf = pw.Document();

    await _ensureFontsLoaded();
    final banglaFont = _cachedBanglaFont ?? pw.Font.helvetica();
    final banglaFontBold = _cachedBanglaFontBold ?? pw.Font.helveticaBold();

    final displayedShopName = shopSettings.shopName.trim().isNotEmpty
        ? shopSettings.shopName.trim()
        : (returnRecord.shopName.trim().isNotEmpty
              ? returnRecord.shopName.trim()
              : '');

    final displayedAddress = shopSettings.address.trim();
    final displayedPhone = shopSettings.phone.trim();

    final qrPayload =
        'GT-RETURN|ID:${returnRecord.returnId}|INV:${returnRecord.invoiceId}|DATE:${returnRecord.formattedDate}|TOTAL:${returnRecord.totalRefundAmount.toStringAsFixed(2)}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
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
                        if (displayedAddress.isNotEmpty)
                          pw.Text(
                            displayedAddress,
                            style: const pw.TextStyle(
                              fontSize: 5.0,
                              color: PdfColors.grey700,
                            ),
                          ),
                        if (displayedPhone.isNotEmpty)
                          pw.Text(
                            'Phone: $displayedPhone',
                            style: const pw.TextStyle(
                              fontSize: 5.0,
                              color: PdfColors.grey700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 4),
                  pw.Container(
                    width: 24,
                    height: 24,
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: qrPayload,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.3, color: PdfColors.grey800),

              // Voucher Title Banner
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                child: pw.Text(
                  'SALES RETURN & REFUND VOUCHER',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 6.0,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              pw.SizedBox(height: 3),

              // Metadata Details
              pw.Text(
                'RETURN ID: ${returnRecord.returnId}',
                style: pw.TextStyle(
                  fontSize: 4.8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'ORIGINAL INVOICE: ${returnRecord.invoiceId}',
                style: const pw.TextStyle(
                  fontSize: 4.5,
                  color: PdfColors.grey800,
                ),
              ),
              pw.Text(
                'DATE: ${returnRecord.formattedDate}  TIME: ${returnRecord.formattedTime}',
                style: const pw.TextStyle(
                  fontSize: 4.2,
                  color: PdfColors.grey700,
                ),
              ),
              if (returnRecord.reason.isNotEmpty)
                pw.Text(
                  'REASON: ${returnRecord.reason}',
                  style: const pw.TextStyle(
                    fontSize: 4.2,
                    color: PdfColors.grey800,
                  ),
                ),

              pw.SizedBox(height: 3),
              pw.Divider(thickness: 0.3, color: PdfColors.grey400),

              // Table Headers
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      'RETURNED ITEM',
                      style: pw.TextStyle(
                        fontSize: 4.2,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      'QTY',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 4.2,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'REFUND',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontSize: 4.2,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 0.3, color: PdfColors.grey400),

              // Items List
              ...returnRecord.items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 1.0),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              item.itemName,
                              style: pw.TextStyle(
                                fontSize: 4.5,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            if (item.partNo.isNotEmpty)
                              pw.Text(
                                'P/N: ${item.partNo}',
                                style: const pw.TextStyle(
                                  fontSize: 3.8,
                                  color: PdfColors.grey600,
                                ),
                              ),
                            pw.Text(
                              item.restock
                                  ? '[Restocked to Stock]'
                                  : '[Damaged / Not Restocked]',
                              style: pw.TextStyle(
                                fontSize: 3.6,
                                color: item.restock
                                    ? PdfColors.green800
                                    : PdfColors.red800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          '${item.quantity}',
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 4.5),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          item.refundAmount.toCurrency(),
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            fontSize: 4.5,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              pw.Divider(thickness: 0.3, color: PdfColors.grey800),

              // Summary Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL REFUND PAID',
                    style: pw.TextStyle(
                      fontSize: 5.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    returnRecord.totalRefundAmount.toCurrency(),
                    style: pw.TextStyle(
                      fontSize: 6.0,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 1.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Items Returned',
                    style: const pw.TextStyle(
                      fontSize: 4.2,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    '${returnRecord.totalQuantity}',
                    style: const pw.TextStyle(
                      fontSize: 4.2,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  'Powered by GearTrack POS System',
                  style: const pw.TextStyle(
                    fontSize: 4.0,
                    color: PdfColors.grey600,
                  ),
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
