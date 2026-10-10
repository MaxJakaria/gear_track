import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:gear_track/core/entities/shop_settings.dart';
import 'package:gear_track/core/utils/currency_formatter.dart';
import 'package:gear_track/feature/point_of_sale/domain/entities/cart_item.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';

/// Service responsible for generating thermal POS PDF receipts.
class PdfReceiptService {
  static pw.Font? _cachedFont;
  static pw.Font? _cachedFontBold;

  static Future<void> _ensureFontsLoaded() async {
    if (_cachedFont != null && _cachedFontBold != null) return;
    try {
      final reg = await rootBundle.load('assets/fonts/pdf_font_regular.ttf');
      final bold = await rootBundle.load('assets/fonts/pdf_font_bold.ttf');
      _cachedFont = pw.Font.ttf(reg);
      _cachedFontBold = pw.Font.ttf(bold);
    } catch (_) {
      _cachedFont ??= pw.Font.helvetica();
      _cachedFontBold ??= pw.Font.helveticaBold();
    }
  }

  static String _pick(String a, String? b) =>
      a.trim().isNotEmpty ? a.trim() : (b?.trim() ?? '');

  /// Formats receipt filename as: partyName_date_billNo.pdf
  static String buildReceiptFileName({
    String? partyName,
    DateTime? date,
    String? billNo,
  }) {
    final cleanParty = (partyName != null && partyName.trim().isNotEmpty)
        ? partyName.trim().replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_')
        : 'WalkIn';

    final d = date ?? DateTime.now();
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final cleanBill = (billNo != null && billNo.trim().isNotEmpty)
        ? billNo.trim().replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_')
        : 'BILL';

    return '${cleanParty}_${dateStr}_$cleanBill.pdf';
  }

  /// Returns candidate download directories in priority order:
  /// 1. Default system Download directory (e.g. /storage/emulated/0/Download on Android, Downloads folder on Windows/Mac)
  /// 2. App-specific external download directory
  /// 3. App-specific documents directory as final safe fallback
  static Future<List<Directory>> getCandidateDownloadDirectories() async {
    final List<Directory> candidates = [];

    if (Platform.isAndroid) {
      // 1. Android public Download folder (/storage/emulated/0/Download)
      try {
        final publicDownload = Directory('/storage/emulated/0/Download');
        if (await publicDownload.exists()) {
          candidates.add(publicDownload);
        }
      } catch (_) {}

      // 2. Default platform downloads directory if provided
      try {
        final d = await getDownloadsDirectory();
        if (d != null && !candidates.any((c) => c.path == d.path)) {
          candidates.add(d);
        }
      } catch (_) {}

      // 3. App external downloads directory (/Android/data/<pkg>/files/Download)
      try {
        final extDirs = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        if (extDirs != null) {
          for (final dir in extDirs) {
            if (!candidates.any((c) => c.path == dir.path)) {
              candidates.add(dir);
            }
          }
        }
      } catch (_) {}

      // 4. App external root directory
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null && !candidates.any((c) => c.path == extDir.path)) {
          candidates.add(extDir);
        }
      } catch (_) {}
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      try {
        final downloads = await getDownloadsDirectory();
        if (downloads != null) {
          candidates.add(downloads);
        }
      } catch (_) {}
    }

    try {
      final appDoc = await getApplicationDocumentsDirectory();
      if (!candidates.any((c) => c.path == appDoc.path)) {
        candidates.add(appDoc);
      }
    } catch (_) {}

    return candidates;
  }

  /// Returns the target directory for saving receipts on the current platform.
  static Future<Directory> getReceiptsDirectory() async {
    final candidates = await getCandidateDownloadDirectories();
    return candidates.isNotEmpty
        ? candidates.first
        : await getApplicationDocumentsDirectory();
  }

  /// Writes pre-generated PDF bytes directly to device default Download storage.
  static Future<File> saveReceiptBytesToDevice({
    required Uint8List bytes,
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
      await file.writeAsBytes(bytes, flush: true);
      return file;
    }

    final candidates = await getCandidateDownloadDirectories();
    for (final dir in candidates) {
      try {
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        final file = File('${dir.path}${Platform.pathSeparator}$fileName');
        await file.writeAsBytes(bytes, flush: true);
        return file;
      } catch (_) {
        // Try next candidate directory
      }
    }

    final fallbackDir = await getApplicationDocumentsDirectory();
    final file = File('${fallbackDir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Generates the receipt and writes the PDF file directly to device default Download storage.
  static Future<File> saveReceiptToDevice({
    required List<CartItem> items,
    required double totalAmount,
    ShopSettings shopSettings = const ShopSettings(),
    InvoiceEntity? invoice,
    Directory? customDirectory,
  }) async {
    final doc = await generateReceipt(
      items,
      totalAmount,
      shopSettings: shopSettings,
      invoice: invoice,
    );
    final bytes = await doc.save();

    final fileName = buildReceiptFileName(
      partyName: invoice?.partyName,
      date: invoice?.saleDate,
      billNo: invoice?.invoiceId,
    );

    if (customDirectory != null) {
      if (!await customDirectory.exists()) {
        await customDirectory.create(recursive: true);
      }
      final file = File(
        '${customDirectory.path}${Platform.pathSeparator}$fileName',
      );
      await file.writeAsBytes(bytes, flush: true);
      return file;
    }

    final candidates = await getCandidateDownloadDirectories();
    for (final dir in candidates) {
      try {
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        final file = File('${dir.path}${Platform.pathSeparator}$fileName');
        await file.writeAsBytes(bytes, flush: true);
        return file;
      } catch (_) {
        // Try next candidate directory
      }
    }

    final fallbackDir = await getApplicationDocumentsDirectory();
    final file = File('${fallbackDir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Generates an 80mm thermal receipt [pw.Document].
  static Future<pw.Document> generateReceipt(
    List<CartItem> items,
    double totalAmount, {
    ShopSettings shopSettings = const ShopSettings(),
    InvoiceEntity? invoice,
  }) async {
    await _ensureFontsLoaded();
    final now = invoice?.saleDate ?? DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final invoiceId = invoice?.invoiceId ?? 'INV-${now.year}-000001';

    final qrPayload =
        invoice?.qrPayload ??
        'GT-RECEIPT|ID:$invoiceId|DATE:$dateStr|TIME:$timeStr|TOTAL:${totalAmount.toStringAsFixed(2)}';

    final shopName = _pick(shopSettings.shopName, invoice?.shopName);
    final shopAddress = _pick(shopSettings.address, invoice?.shopAddress);
    final shopPhone = _pick(shopSettings.phone, invoice?.shopPhone);
    final shopEmail = _pick(shopSettings.email, invoice?.shopEmail);

    final billNo = invoice?.invoiceId ?? invoiceId;
    final billingDate = invoice?.formattedDate ?? dateStr;
    final partyName = invoice?.partyName.trim() ?? '';
    final partyAddress = invoice?.partyAddress.trim() ?? '';
    final servedBy = invoice?.servedBy.trim() ?? '';
    final entryTime = DateFormat('dd/MM/yyyy hh:mm a').format(now);

    final displayItems = items.isNotEmpty
        ? items
        : (invoice?.items ?? [])
              .map(
                (i) => CartItem(
                  id: i.productId,
                  productId: i.productId,
                  batchId: i.batchId,
                  itemName: i.itemName,
                  partNo: i.partNo,
                  costCode: i.costCode,
                  quantity: i.quantity,
                  sellPrice: i.sellPrice,
                  availableStock: i.quantity,
                ),
              )
              .toList();

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        orientation: pw.PageOrientation.portrait,
        margin: const pw.EdgeInsets.all(8),
        theme: pw.ThemeData.withFont(
          base: _cachedFont ?? pw.Font.helvetica(),
          bold: _cachedFontBold ?? pw.Font.helveticaBold(),
        ),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _buildHeader(shopName, shopAddress, shopPhone, shopEmail),
            pw.SizedBox(height: 4),
            _buildMetaSection(
              billNo,
              billingDate,
              partyName,
              partyAddress,
              servedBy,
              entryTime,
            ),
            pw.SizedBox(height: 4),
            _buildItemsTable(context, displayItems),
            pw.SizedBox(height: 4),
            _buildTotalSection(totalAmount, invoice: invoice),
            pw.SizedBox(height: 6),
            _buildFooter(qrPayload),
          ],
        ),
      ),
    );

    return pdf;
  }

  // --- UI Component Builders ---

  static pw.Widget _buildHeader(
    String name,
    String address,
    String phone,
    String email,
  ) {
    return pw.Center(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (name.isNotEmpty)
            pw.Text(
              name,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 8.0,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          if (address.isNotEmpty) ...[
            pw.SizedBox(height: 1),
            pw.Text(
              address,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 5.2),
            ),
          ],
          if (phone.isNotEmpty) ...[
            pw.SizedBox(height: 0.8),
            pw.Text(
              phone.toLowerCase().startsWith('phone') ||
                      phone.toLowerCase().startsWith('mobile')
                  ? phone
                  : 'Mobile: $phone',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 5.0),
            ),
          ],
          if (email.isNotEmpty) ...[
            pw.SizedBox(height: 0.8),
            pw.Text(
              email.toLowerCase().startsWith('email') ? email : 'Email: $email',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 5.0),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildMetaSection(
    String billNo,
    String billingDate,
    String partyName,
    String partyAddress,
    String servedBy,
    String entryTime,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          flex: 10,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (billNo.isNotEmpty) _buildMetaItem('Bill no', billNo),
              if (billingDate.isNotEmpty)
                _buildMetaItem('Billing date', billingDate),
              if (partyName.isNotEmpty) _buildMetaItem('Party Name', partyName),
              if (partyAddress.isNotEmpty)
                _buildMetaItem('Party address', partyAddress),
            ],
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Expanded(
          flex: 11,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (servedBy.isNotEmpty)
                    _buildMetaItem('Served by', servedBy),
                  if (entryTime.isNotEmpty)
                    _buildMetaItem('Entry Time', entryTime),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(pw.Context context, List<CartItem> items) {
    final centered = {for (int i = 0; i < 6; i++) i: pw.Alignment.center};
    return pw.TableHelper.fromTextArray(
      context: context,
      headers: const [
        'Sl.',
        'Product Name',
        'Part No',
        'Qty',
        'Unit Price',
        'Total Price',
      ],
      data: [
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
      headerStyle: pw.TextStyle(fontSize: 4.0, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 3.8),
      headerAlignments: centered,
      cellAlignments: centered,
      columnWidths: const {
        0: pw.FlexColumnWidth(0.7),
        1: pw.FlexColumnWidth(3.2),
        2: pw.FlexColumnWidth(1.9),
        3: pw.FlexColumnWidth(1.1),
        4: pw.FlexColumnWidth(1.6),
        5: pw.FlexColumnWidth(1.8),
      },
      cellPadding: const pw.EdgeInsets.symmetric(
        horizontal: 0.8,
        vertical: 1.2,
      ),
      headerPadding: const pw.EdgeInsets.symmetric(
        horizontal: 0.8,
        vertical: 2.0,
      ),
    );
  }

  static pw.Widget _buildTotalSection(
    double total, {
    InvoiceEntity? invoice,
  }) {
    final bool hasDue = invoice != null && invoice.dueAmount > 0.001;
    final style = pw.TextStyle(fontSize: 5.5, fontWeight: pw.FontWeight.bold);
    final rowStyle = const pw.TextStyle(fontSize: 5.0);
    final dueStyle = pw.TextStyle(
      fontSize: 5.5,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.red700,
    );

    if (hasDue) {
      final paid = invoice.paidAmount;
      final due = invoice.dueAmount;
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text('Total : ', style: style),
                  pw.Text(total.toCurrency(), style: style),
                ],
              ),
              pw.SizedBox(height: 1.5),
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text('Paid : ', style: rowStyle),
                  pw.Text(paid.toCurrency(), style: rowStyle),
                ],
              ),
              pw.SizedBox(height: 1.5),
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text('Due : ', style: dueStyle),
                  pw.Text(due.toCurrency(), style: dueStyle),
                ],
              ),
            ],
          ),
        ],
      );
    }

    // Fully Paid -> Paid Stamp (Sill) + Total row
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // "PAID" stamp / seal
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.green700, width: 1.2),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
          ),
          child: pw.Transform.rotate(
            angle: -0.08,
            child: pw.Text(
              'PAID',
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text('Total : ', style: style),
            pw.Text(total.toCurrency(), style: style),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(String qr) {
    return pw.Center(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (qr.isNotEmpty) ...[
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: qr,
              width: 20,
              height: 20,
            ),
            pw.SizedBox(height: 2.5),
          ],
          pw.Text(
            'May Allah put Barakah in your purchase.',
            style: const pw.TextStyle(fontSize: 4.5),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetaItem(
    String label,
    String value, {
    bool alignRight = false,
  }) {
    final clean = value.trim();
    if (clean.isEmpty) return pw.SizedBox.shrink();
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 0.4),
      child: pw.RichText(
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(
                fontSize: 4.6,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.TextSpan(text: clean, style: const pw.TextStyle(fontSize: 4.6)),
          ],
        ),
      ),
    );
  }
}
