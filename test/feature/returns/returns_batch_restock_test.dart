import 'package:flutter_test/flutter_test.dart';
import 'package:gear_track/feature/inventory/domain/entities/grouped_product.dart';
import 'package:gear_track/feature/inventory/domain/entities/product.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';
import 'package:gear_track/feature/returns/domain/entities/return_entity.dart';

void main() {
  group('Return and Batch Restock Tests', () {
    test('InvoiceItemEntity correctly preserves batchId for traceability', () {
      const invoiceItem = InvoiceItemEntity(
        productId: 'PROD_001',
        batchId: 'BATCH_99',
        itemName: 'Brake Pad',
        partNo: 'BP-01',
        quantity: 5,
        sellPrice: 150.0,
        costCode: 'CC-PAD',
      );

      expect(invoiceItem.productId, 'PROD_001');
      expect(invoiceItem.batchId, 'BATCH_99');
      expect(invoiceItem.returnableQuantity, 5);
      expect(invoiceItem.isFullyReturned, false);
    });

    test('ReturnItemEntity correctly captures batchId from invoice', () {
      const returnItem = ReturnItemEntity(
        productId: 'PROD_001',
        batchId: 'BATCH_99',
        itemName: 'Brake Pad',
        partNo: 'BP-01',
        quantity: 2,
        sellPrice: 150.0,
        costCode: 'CC-PAD',
        restock: true,
      );

      expect(returnItem.productId, 'PROD_001');
      expect(returnItem.batchId, 'BATCH_99');
      expect(returnItem.refundAmount, 300.0);
      expect(returnItem.restock, true);
    });

    test(
      'Restocking an out-of-stock batch updates batch stockCount and GroupedProduct total stock',
      () {
        final now = DateTime(2026, 3, 1);

        // Initially out of stock batch
        final batch1 = Product(
          id: 'PROD_001/BATCH_99',
          entryDate: now,
          partNo: 'BP-01',
          itemName: 'Brake Pad',
          model: 'Ceramic',
          costCode: 'CC-PAD',
          initialQuantity: 10,
          stockCount: 0, // completely sold out
        );

        final initialGrouped = GroupedProduct.fromBatches('BP-01', [batch1]);
        expect(initialGrouped.totalStockCount, 0);
        expect(initialGrouped.hasOutOfStockBatch, true);
        expect(initialGrouped.hasInStockBatch, false);
        expect(initialGrouped.batchCount, 1);

        // Simulate restock of 2 units from return
        const returnedQty = 2;
        final restockedBatch1 = Product(
          id: batch1.id,
          entryDate: batch1.entryDate,
          partNo: batch1.partNo,
          itemName: batch1.itemName,
          model: batch1.model,
          costCode: batch1.costCode,
          initialQuantity: batch1.initialQuantity,
          stockCount: batch1.stockCount + returnedQty,
        );

        final updatedGrouped = GroupedProduct.fromBatches('BP-01', [
          restockedBatch1,
        ]);
        expect(updatedGrouped.totalStockCount, 2);
        expect(updatedGrouped.hasOutOfStockBatch, false);
        expect(updatedGrouped.hasInStockBatch, true);
        expect(updatedGrouped.batchCount, 1);
      },
    );
  });
}
