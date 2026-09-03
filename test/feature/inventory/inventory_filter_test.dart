import 'package:flutter_test/flutter_test.dart';
import 'package:gear_track/feature/inventory/domain/entities/product.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';

void main() {
  group('StockFilter & InventoryState filtering tests', () {
    final date = DateTime(2026, 1, 1);

    // Product 1: In stock (2 batches: 10 units + 5 units = total 15, low batch exists)
    final p1Batch1 = Product(
      id: '1',
      entryDate: date,
      partNo: 'P01-B1',
      itemName: 'Brake Disc',
      model: 'Model X',
      costCode: 'CC-01',
      initialQuantity: 10,
      stockCount: 10,
    );
    final p1Batch2 = Product(
      id: '2',
      entryDate: date.add(const Duration(days: 1)),
      partNo: 'P01-B2',
      itemName: 'Brake Disc',
      model: 'Model X',
      costCode: 'CC-02',
      initialQuantity: 5,
      stockCount: 3, // Low batch (1-5)
    );

    // Product 2: Low stock at product level (1 batch: 4 units = total 4)
    final p2Batch1 = Product(
      id: '3',
      entryDate: date,
      partNo: 'P02-B1',
      itemName: 'Clutch Plate',
      model: 'Model Y',
      costCode: 'CC-03',
      initialQuantity: 5,
      stockCount: 4,
    );

    // Product 3: Out of stock at product level (1 batch: 0 units = total 0)
    final p3Batch1 = Product(
      id: '4',
      entryDate: date,
      partNo: 'P03-B1',
      itemName: 'Spark Plug',
      model: 'Model Z',
      costCode: 'CC-04',
      initialQuantity: 10,
      stockCount: 0,
    );

    // Product 4: In stock product (20 units) but has one out of stock batch (0 units) -> total 20
    final p4Batch1 = Product(
      id: '5',
      entryDate: date,
      partNo: 'P04-B1',
      itemName: 'Oil Filter',
      model: 'Model W',
      costCode: 'CC-05',
      initialQuantity: 20,
      stockCount: 20,
    );
    final p4Batch2 = Product(
      id: '6',
      entryDate: date.add(const Duration(days: 2)),
      partNo: 'P04-B2',
      itemName: 'Oil Filter',
      model: 'Model W',
      costCode: 'CC-06',
      initialQuantity: 5,
      stockCount: 0, // Out of stock batch
    );

    final p1Batch3 = Product(
      id: '7',
      entryDate: date.add(const Duration(days: 2)),
      partNo: 'P01-B3',
      itemName: 'Brake Disc',
      model: 'Model X',
      costCode: 'CC-07',
      initialQuantity: 5,
      stockCount: 2, // Another Low batch (1-5) on Product 1
    );

    final p3Batch2 = Product(
      id: '8',
      entryDate: date.add(const Duration(days: 1)),
      partNo: 'P03-B2',
      itemName: 'Spark Plug',
      model: 'Model Z',
      costCode: 'CC-04B',
      initialQuantity: 5,
      stockCount: 0, // Another Out of stock batch on Spark Plug
    );

    final allProducts = [
      p1Batch1,
      p1Batch2,
      p1Batch3,
      p2Batch1,
      p3Batch1,
      p3Batch2,
      p4Batch1,
      p4Batch2,
    ];

    test('Default filter (StockFilter.all) returns all 4 grouped products', () {
      final state = InventoryLoaded(
        products: allProducts,
        filteredProducts: allProducts,
        activeFilter: StockFilter.all,
      );

      expect(state.totalSkus, 4);
      expect(state.filteredGroupedProducts.length, 4);
    });

    test('StockFilter.inStock returns products with totalStockCount > 0', () {
      final state = InventoryLoaded(
        products: allProducts,
        filteredProducts: allProducts,
        activeFilter: StockFilter.inStock,
      );

      final results = state.filteredGroupedProducts;
      // Products 1, 2, 4 have totalStock > 0
      expect(results.length, 3);
      expect(results.map((p) => p.itemName), containsAll(['Brake Disc', 'Clutch Plate', 'Oil Filter']));
      expect(results.map((p) => p.itemName), isNot(contains('Spark Plug')));
    });

    test('StockFilter.lowStockProduct returns products with totalStock 1..5', () {
      final state = InventoryLoaded(
        products: allProducts,
        filteredProducts: allProducts,
        activeFilter: StockFilter.lowStockProduct,
      );

      final results = state.filteredGroupedProducts;
      // Only Product 2 (Clutch Plate, totalStock=4) is low stock at product level
      expect(results.length, 1);
      expect(results.first.itemName, 'Clutch Plate');
      expect(state.lowStockProductCount, 1);
    });

    test('StockFilter.lowStockBatch returns products having at least one batch with 1..5 units and filteredBatches returns matching batches', () {
      final state = InventoryLoaded(
        products: allProducts,
        filteredProducts: allProducts,
        activeFilter: StockFilter.lowStockBatch,
      );

      final results = state.filteredGroupedProducts;
      // Product 1 (has batch with 3 and 2) and Product 2 (has batch with 4)
      expect(results.length, 2);
      expect(results.map((p) => p.itemName), containsAll(['Brake Disc', 'Clutch Plate']));
      expect(state.lowStockBatchCount, 3);
      expect(state.filteredBatches.length, 3);
      expect(state.filteredBatches.map((b) => b.partNo), containsAll(['P01-B2', 'P01-B3', 'P02-B1']));
      expect(state.filteredBatchesGrouped.length, 2);
      expect(state.filteredBatchesGrouped.firstWhere((g) => g.itemName == 'Brake Disc').batches.length, 2);
    });

    test('StockFilter.outOfStockProduct returns products with totalStock <= 0', () {
      final state = InventoryLoaded(
        products: allProducts,
        filteredProducts: allProducts,
        activeFilter: StockFilter.outOfStockProduct,
      );

      final results = state.filteredGroupedProducts;
      // Only Product 3 (Spark Plug, totalStock=0) is out of stock at product level
      expect(results.length, 1);
      expect(results.first.itemName, 'Spark Plug');
      expect(state.outOfStockProductCount, 1);
    });

    test('StockFilter.outOfStockBatch groups multiple out of stock batches under 1 product card in filteredBatchesGrouped', () {
      final state = InventoryLoaded(
        products: allProducts,
        filteredProducts: allProducts,
        activeFilter: StockFilter.outOfStockBatch,
      );

      final results = state.filteredGroupedProducts;
      // Product 3 (Spark Plug has batches with 0) and Product 4 (Oil Filter has batch with 0)
      expect(results.length, 2);
      expect(results.map((p) => p.itemName), containsAll(['Spark Plug', 'Oil Filter']));
      expect(state.outOfStockBatchCount, 3);
      expect(state.filteredBatches.length, 3);
      expect(state.filteredBatches.map((b) => b.partNo), containsAll(['P03-B1', 'P03-B2', 'P04-B2']));

      // filteredBatchesGrouped groups by product: 2 cards total
      final grouped = state.filteredBatchesGrouped;
      expect(grouped.length, 2);

      // Spark plug card has both out of stock batches
      final sparkPlugCard = grouped.firstWhere((g) => g.itemName == 'Spark Plug');
      expect(sparkPlugCard.batches.length, 2);
      expect(sparkPlugCard.batches.map((b) => b.partNo), containsAll(['P03-B1', 'P03-B2']));

      // Oil filter card has 1 out of stock batch
      final oilFilterCard = grouped.firstWhere((g) => g.itemName == 'Oil Filter');
      expect(oilFilterCard.batches.length, 1);
      expect(oilFilterCard.batches.first.partNo, 'P04-B2');
    });

    test('Counts are accurately calculated', () {
      final state = InventoryLoaded(
        products: allProducts,
        filteredProducts: allProducts,
      );

      expect(state.totalSkus, 4);
      expect(state.inStockCount, 3);
      expect(state.lowStockProductCount, 1);
      expect(state.lowStockBatchCount, 3);
      expect(state.outOfStockProductCount, 1);
      expect(state.outOfStockBatchCount, 3);
    });
  });
}
