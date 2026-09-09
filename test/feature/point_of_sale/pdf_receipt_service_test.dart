import 'package:flutter_test/flutter_test.dart';
import 'package:gear_track/core/entities/shop_settings.dart';
import 'package:gear_track/feature/point_of_sale/domain/entities/cart_item.dart';
import 'package:gear_track/feature/point_of_sale/utils/pdf_receipt_service.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfReceiptService Receipt Generation Tests', () {
    test('generateReceipt generates valid PDF with custom shop settings and invoice meta', () async {
      const shopSettings = ShopSettings(
        shopName: 'GearTrack Auto Solutions',
        address: 'Dhaka, Bangladesh',
        phone: '01700000000, 01800000000',
        email: 'support@geartrack.com',
      );

      final items = [
        const CartItem(
          id: '1',
          productId: 'prod_1',
          batchId: 'batch_1',
          itemName: 'Brake Pad Premium',
          partNo: 'BP-001',
          costCode: 'CC1',
          quantity: 2,
          sellPrice: 1500.0,
          availableStock: 10,
        ),
      ];

      final invoice = InvoiceEntity(
        invoiceId: 'INV-POS01-20260909-0001',
        saleDate: DateTime(2026, 9, 9, 17, 30, 0),
        totalAmount: 3000.0,
        totalItems: 2,
        items: const [
          InvoiceItemEntity(
            productId: 'prod_1',
            batchId: 'batch_1',
            itemName: 'Brake Pad Premium',
            partNo: 'BP-001',
            quantity: 2,
            sellPrice: 1500.0,
          ),
        ],
        partyName: 'Rahim Motors',
        partyAddress: 'Mirpur-10, Dhaka',
        servedBy: 'Cashier-02',
      );

      final doc = await PdfReceiptService.generateReceipt(
        items,
        3000.0,
        shopSettings: shopSettings,
        invoice: invoice,
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
    });

    test('generateReceipt falls back gracefully to default party values when not specified', () async {
      final items = [
        const CartItem(
          id: '2',
          productId: 'prod_2',
          batchId: 'batch_2',
          itemName: 'Oil Filter',
          partNo: 'OF-100',
          costCode: 'CC2',
          quantity: 1,
          sellPrice: 450.0,
          availableStock: 5,
        ),
      ];

      final doc = await PdfReceiptService.generateReceipt(
        items,
        450.0,
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
    });

    test('InvoiceEntity and InvoiceModel have empty string defaults without dummy preset data', () {
      final invoice = InvoiceEntity(
        invoiceId: 'INV-TEST-001',
        saleDate: DateTime.now(),
        totalAmount: 100.0,
        totalItems: 1,
        items: const [],
      );

      expect(invoice.partyName, '');
      expect(invoice.partyAddress, '');
      expect(invoice.servedBy, '');
    });

    test('buildReceiptFileName formats filename as partyName_date_billNo.pdf', () {
      final fileName = PdfReceiptService.buildReceiptFileName(
        partyName: 'Rahim Motors',
        date: DateTime(2026, 9, 10),
        billNo: 'INV-260910-001',
      );
      expect(fileName, 'Rahim_Motors_2026-09-10_INV-260910-001.pdf');
    });

    test('buildReceiptFileName falls back gracefully when partyName or billNo are empty', () {
      final fileName = PdfReceiptService.buildReceiptFileName(
        partyName: '',
        date: DateTime(2026, 9, 10),
        billNo: '',
      );
      expect(fileName, 'WalkIn_2026-09-10_BILL.pdf');
    });
  });
}
