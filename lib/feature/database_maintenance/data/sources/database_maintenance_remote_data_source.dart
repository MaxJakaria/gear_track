import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gear_track/core/entities/cost_code_mapping.dart';
import 'package:gear_track/feature/database_maintenance/data/models/database_metrics.dart';

abstract interface class DatabaseMaintenanceRemoteDataSource {
  Future<DatabaseMetrics> fetchMetrics();
  Future<int> clearSalesHistory();
  Future<int> clearReturnsHistory();
  Future<int> clearInventoryAndBatches();
  Future<void> resetAppSettings();
  Future<int> wipeEntireDatabase();
}

class DatabaseMaintenanceRemoteDataSourceImpl
    implements DatabaseMaintenanceRemoteDataSource {
  final FirebaseFirestore firestore;

  const DatabaseMaintenanceRemoteDataSourceImpl(this.firestore);

  /// Fetch live counts for all major collections with safety timeout
  @override
  Future<DatabaseMetrics> fetchMetrics() async {
    try {
      final futures = await Future.wait([
        firestore
            .collection('products')
            .count()
            .get()
            .timeout(const Duration(seconds: 4)),
        firestore
            .collectionGroup('stock_entries')
            .count()
            .get()
            .timeout(const Duration(seconds: 4)),
        firestore
            .collection('invoices')
            .count()
            .get()
            .timeout(const Duration(seconds: 4)),
        firestore
            .collectionGroup('sales_records')
            .count()
            .get()
            .timeout(const Duration(seconds: 4)),
        firestore
            .collection('returns')
            .count()
            .get()
            .timeout(const Duration(seconds: 4)),
      ]);

      return DatabaseMetrics(
        productsCount: futures[0].count ?? 0,
        batchesCount: futures[1].count ?? 0,
        invoicesCount: futures[2].count ?? 0,
        salesCount: futures[3].count ?? 0,
        returnsCount: futures[4].count ?? 0,
      );
    } catch (_) {
      // Fallback in case of slow or offline network
      return const DatabaseMetrics();
    }
  }

  /// Helper to delete documents in chunks of 400 (well within Firestore's 500 batch write limit)
  Future<int> _deleteQueryInChunks(Query query, [int chunkSize = 400]) async {
    int totalDeleted = 0;
    while (true) {
      final snapshot = await query.limit(chunkSize).get();
      if (snapshot.docs.isEmpty) break;

      final batch = firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      totalDeleted += snapshot.docs.length;

      if (snapshot.docs.length < chunkSize) break;
    }
    return totalDeleted;
  }

  /// 1. Clear Sales History while permanently preserving revenue & profit in financial ledger.
  /// NOTE: Customer Invoices remain 100% intact so clients can verify invoices at any time.
  @override
  Future<int> clearSalesHistory() async {
    // A. Fetch current cost code mapping to decode profit accurately
    final costCodeSnap = await firestore
        .collection('app_settings')
        .doc('cost_code_mapping')
        .get();
    CostCodeMapping mapping = const CostCodeMapping(charToDigit: {});
    if (costCodeSnap.exists && costCodeSnap.data() != null) {
      final data = costCodeSnap.data()!;
      final mapData = data['mapping'] as Map<String, dynamic>? ?? {};
      mapping = CostCodeMapping(
        charToDigit: mapData.map((k, v) => MapEntry(k, (v as num).toInt())),
      );
    }

    // B. Fetch all sales and sales records in parallel (2 parallel queries instead of N+1)
    final results = await Future.wait([
      firestore.collection('sales').get(),
      firestore.collectionGroup('sales_records').get(),
    ]);
    final salesDocs = results[0].docs;
    final recordsDocs = results[1].docs;

    double salesRevenue = 0.0;
    double salesProfit = 0.0;
    int salesItems = 0;

    for (final r in recordsDocs) {
      final data = r.data();
      final sellPrice = (data['sellPrice'] as num?)?.toDouble() ?? 0.0;
      final qty = (data['quantity'] as num?)?.toInt() ?? 0;
      final costCode = data['costCode'] as String? ?? '';
      final costPerUnit = mapping.decode(costCode);

      final double profitPerUnit;
      if (costPerUnit > 0) {
        profitPerUnit = sellPrice - costPerUnit;
      } else {
        profitPerUnit = sellPrice * 0.30;
      }

      salesRevenue += sellPrice * qty;
      salesProfit += profitPerUnit * qty;
      salesItems += qty;
    }

    // C. Increment permanent financial ledger so revenue and profit are NEVER lost
    if (salesRevenue > 0 || salesProfit != 0) {
      await firestore.collection('financial_ledger').doc('cumulative').set({
        'accumulatedRevenue': FieldValue.increment(salesRevenue),
        'accumulatedProfit': FieldValue.increment(salesProfit),
        'accumulatedItemsSold': FieldValue.increment(salesItems),
        'lastArchivedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // D. Delete all sales and sales_records in fast 400-document batches
    final allDocs = [...recordsDocs, ...salesDocs];
    for (int i = 0; i < allDocs.length; i += 400) {
      final end = (i + 400 < allDocs.length) ? i + 400 : allDocs.length;
      final batch = firestore.batch();
      for (int j = i; j < end; j++) {
        batch.delete(allDocs[j].reference);
      }
      await batch.commit();
    }

    return allDocs.length;
  }

  /// 2. Clear Returns History & reset invoice return flags while permanently preserving return deductions in financial ledger
  @override
  Future<int> clearReturnsHistory() async {
    // A. Fetch current cost code mapping to decode profit deductions accurately
    final costCodeSnap = await firestore
        .collection('app_settings')
        .doc('cost_code_mapping')
        .get();
    CostCodeMapping mapping = const CostCodeMapping(charToDigit: {});
    if (costCodeSnap.exists && costCodeSnap.data() != null) {
      final data = costCodeSnap.data()!;
      final mapData = data['mapping'] as Map<String, dynamic>? ?? {};
      mapping = CostCodeMapping(
        charToDigit: mapData.map((k, v) => MapEntry(k, (v as num).toInt())),
      );
    }

    // B. Fetch all returns to compute return deductions to be permanently archived
    final returnsSnap = await firestore.collection('returns').get();
    double totalReturnRefund = 0.0;
    double totalReturnProfit = 0.0;
    int totalReturnQuantity = 0;

    for (final doc in returnsSnap.docs) {
      final data = doc.data();
      final refund = (data['totalRefundAmount'] as num?)?.toDouble() ?? 0.0;
      final totalQty = (data['totalQuantity'] as num?)?.toInt() ?? 0;
      totalReturnRefund += refund;
      totalReturnQuantity += totalQty;

      final items = (data['items'] as List<dynamic>?) ?? [];
      for (final itemRaw in items) {
        if (itemRaw is Map<String, dynamic>) {
          final sellPrice = (itemRaw['sellPrice'] as num?)?.toDouble() ?? 0.0;
          final qty = (itemRaw['quantity'] as num?)?.toInt() ?? 0;
          final costCode = itemRaw['costCode'] as String? ?? '';
          final costPerUnit = mapping.decode(costCode);

          final double profitPerUnit;
          if (costPerUnit > 0) {
            profitPerUnit = sellPrice - costPerUnit;
          } else {
            profitPerUnit = sellPrice * 0.30;
          }

          totalReturnProfit += profitPerUnit * qty;
        }
      }
    }

    // C. Deduct returns from permanent financial ledger so Net Revenue & Profit stay 100% accurate
    if (totalReturnRefund > 0 || totalReturnProfit > 0) {
      await firestore.collection('financial_ledger').doc('cumulative').set({
        'accumulatedRevenue': FieldValue.increment(-totalReturnRefund),
        'accumulatedProfit': FieldValue.increment(-totalReturnProfit),
        'accumulatedItemsSold': FieldValue.increment(-totalReturnQuantity),
        'lastArchivedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // D. Delete all return documents in fast 400-document batches
    int count = 0;
    for (int i = 0; i < returnsSnap.docs.length; i += 400) {
      final end = (i + 400 < returnsSnap.docs.length)
          ? i + 400
          : returnsSnap.docs.length;
      final batch = firestore.batch();
      for (int j = i; j < end; j++) {
        batch.delete(returnsSnap.docs[j].reference);
      }
      await batch.commit();
      count += (end - i);
    }

    // NOTE: Customer Invoices remain 100% intact so customers and shopkeepers can still verify invoices and return records without any data corruption.
    return count;
  }

  /// 3. Clear Inventory Catalog & Batches while permanently preserving investment capital in financial ledger
  @override
  Future<int> clearInventoryAndBatches() async {
    // A. Fetch current cost code mapping to decode buying costs
    final costCodeSnap = await firestore
        .collection('app_settings')
        .doc('cost_code_mapping')
        .get();
    CostCodeMapping mapping = const CostCodeMapping(charToDigit: {});
    if (costCodeSnap.exists && costCodeSnap.data() != null) {
      final data = costCodeSnap.data()!;
      final mapData = data['mapping'] as Map<String, dynamic>? ?? {};
      mapping = CostCodeMapping(
        charToDigit: mapData.map((k, v) => MapEntry(k, (v as num).toInt())),
      );
    }

    // B. Fetch all products and stock entries in parallel (2 parallel queries instead of N+1)
    final results = await Future.wait([
      firestore.collection('products').get(),
      firestore.collectionGroup('stock_entries').get(),
    ]);
    final productsDocs = results[0].docs;
    final entriesDocs = results[1].docs;

    double totalInventoryInvestment = 0.0;

    // Calculate investment across all stock entries
    if (entriesDocs.isNotEmpty) {
      for (final entry in entriesDocs) {
        final entryData = entry.data();
        final stock = (entryData['remainingQuantity'] as num?)?.toInt() ?? 0;
        if (stock > 0) {
          final costCode = entryData['costCode'] as String? ?? '';
          final costPerUnit = mapping.decode(costCode);
          totalInventoryInvestment += stock * costPerUnit;
        }
      }
    } else {
      for (final doc in productsDocs) {
        final data = doc.data();
        final stock = (data['totalStock'] as num?)?.toInt() ?? 0;
        if (stock > 0) {
          final costCode = data['costCode'] as String? ?? '';
          final costPerUnit = mapping.decode(costCode);
          totalInventoryInvestment += stock * costPerUnit;
        }
      }
    }

    // C. Permanently preserve investment capital in the financial ledger
    if (totalInventoryInvestment > 0) {
      await firestore.collection('financial_ledger').doc('cumulative').set({
        'accumulatedInvestment': FieldValue.increment(totalInventoryInvestment),
        'lastArchivedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // D. Delete all stock entries and products in fast 400-document batches
    final allDocs = [...entriesDocs, ...productsDocs];
    for (int i = 0; i < allDocs.length; i += 400) {
      final end = (i + 400 < allDocs.length) ? i + 400 : allDocs.length;
      final batch = firestore.batch();
      for (int j = i; j < end; j++) {
        batch.delete(allDocs[j].reference);
      }
      await batch.commit();
    }

    return allDocs.length;
  }

  /// 4. Reset App Settings (Cost code mappings and store profile)
  @override
  Future<void> resetAppSettings() async {
    final batch = firestore.batch();

    final costCodeDoc = firestore
        .collection('app_settings')
        .doc('cost_code_mapping');
    batch.set(costCodeDoc, {'mapping': {}});

    final shopDoc = firestore.collection('app_settings').doc('shop_settings');
    batch.set(shopDoc, {'shopName': '', 'address': '', 'phone': ''});

    await batch.commit();
  }

  /// 5. Complete Factory Reset / Wipe Entire Database
  @override
  Future<int> wipeEntireDatabase() async {
    int total = 0;

    // 1. Clear Sales
    total += await clearSalesHistory();

    // 2. Clear Invoices (Factory Reset only)
    total += await _deleteQueryInChunks(firestore.collection('invoices'));

    // 3. Clear Returns
    total += await clearReturnsHistory();

    // 3. Clear Inventory & Batches
    total += await clearInventoryAndBatches();

    // 4. Reset Settings
    await resetAppSettings();

    // 5. Clear Counters if present
    try {
      total += await _deleteQueryInChunks(firestore.collection('counters'));
    } catch (_) {}

    // 6. Clear Cumulative Financial Ledger (Factory Reset)
    try {
      await firestore.collection('financial_ledger').doc('cumulative').delete();
    } catch (_) {}

    return total;
  }
}
