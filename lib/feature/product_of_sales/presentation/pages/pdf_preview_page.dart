import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:gear_track/feature/product_of_sales/utils/pdf_receipt_service.dart';
import 'package:gear_track/feature/product_of_sales/domain/entities/cart_item.dart';

import 'dart:typed_data';

class PdfPreviewPage extends StatelessWidget {
  final Uint8List pdfBytes;

  const PdfPreviewPage({
    super.key,
    required this.pdfBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Preview'),
      ),
      body: PdfPreview(
        build: (format) async => pdfBytes,
        actions: const [],
        allowPrinting: false,
        allowSharing: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        initialPageFormat: PdfPageFormat.roll80,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Printing.layoutPdf(
                onLayout: (format) async => pdfBytes,
                name: 'Receipt',
              );
            },
            icon: const Icon(Icons.print, size: 22),
            label: const Text(
              'Print Receipt',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
