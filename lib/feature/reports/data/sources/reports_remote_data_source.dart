import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gear_track/feature/reports/domain/entities/financial_ledger.dart';
import '../../../../feature/inventory/data/models/product_model.dart';
import '../../../../feature/point_of_sale/data/models/sale_model.dart';
import '../../../../feature/returns/data/models/return_model.dart';

abstract class ReportsRemoteDataSource {
  Future<List<SaleModel>> getAllSales();
  Future<List<ProductModel>> getAllProducts();
  Future<List<ReturnModel>> getAllReturns();
  Future<FinancialLedger> getFinancialLedger();
}

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  final FirebaseFirestore firestore;

  ReportsRemoteDataSourceImpl({required this.firestore});

  @override
  Future<FinancialLedger> getFinancialLedger() async {
    try {
      final doc =
          await firestore.collection('financial_ledger').doc('cumulative').get();
      if (!doc.exists || doc.data() == null) {
        return const FinancialLedger();
      }
      return FinancialLedger.fromMap(doc.data());
    } catch (_) {
      return const FinancialLedger();
    }
  }

  @override
  Future<List<SaleModel>> getAllSales() async {
    final snapshot = await firestore.collectionGroup('sales_records').get();
    final list = snapshot.docs.map((doc) => SaleModel.fromFirestore(doc)).toList();
    list.sort((a, b) => b.saleDate.compareTo(a.saleDate));
    return list;
  }

  @override
  Future<List<ReturnModel>> getAllReturns() async {
    try {
      final snapshot = await firestore
          .collection('returns')
          .orderBy('returnDate', descending: true)
          .get();
      return snapshot.docs.map((doc) => ReturnModel.fromFirestore(doc)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<ProductModel>> getAllProducts() async {
    final results = await Future.wait([
      firestore.collection('products').get(),
      firestore.collectionGroup('stock_entries').get(),
    ]);

    final productsSnapshot = results[0];
    final stockEntriesSnapshot = results[1];

    final Map<String, Map<String, dynamic>> productInfoMap = {};
    for (final doc in productsSnapshot.docs) {
      productInfoMap[doc.id] = doc.data();
    }

    final List<ProductModel> allBatches = [];

    // Group batches under products
    final Map<String, List<DocumentSnapshot<Map<String, dynamic>>>> entriesByProduct = {};
    for (final entryDoc in stockEntriesSnapshot.docs) {
      final parentProductId = entryDoc.reference.parent.parent?.id ?? '';
      entriesByProduct.putIfAbsent(parentProductId, () => []).add(entryDoc);
    }

    for (final productDoc in productsSnapshot.docs) {
      final productData = productDoc.data();
      final defaultPartNo = productData['partNo'] ?? productDoc.id;
      final itemName = productData['itemName'] ?? '';
      final model = productData['model'] ?? '';
      final totalStock = (productData['totalStock'] as num?)?.toInt() ?? 0;

      final entries = entriesByProduct[productDoc.id];
      if (entries == null || entries.isEmpty) {
        allBatches.add(
          ProductModel(
            id: productDoc.id,
            entryDate: (productData['entryDate'] is Timestamp)
                ? (productData['entryDate'] as Timestamp).toDate()
                : DateTime.now(),
            partNo: defaultPartNo,
            itemName: itemName,
            model: model,
            costCode: productData['costCode'] ?? '',
            initialQuantity: totalStock,
            stockCount: totalStock,
          ),
        );
      } else {
        for (final entryDoc in entries) {
          final entryData = entryDoc.data()!;
          final batchPartNo =
              (entryData['partNo'] as String?)?.isNotEmpty == true
                  ? entryData['partNo'] as String
                  : defaultPartNo;

          allBatches.add(
            ProductModel(
              id: entryDoc.id,
              entryDate: (entryData['date'] is Timestamp)
                  ? (entryData['date'] as Timestamp).toDate()
                  : DateTime.now(),
              partNo: batchPartNo,
              itemName: itemName,
              model: model,
              costCode: entryData['costCode'] ?? '',
              initialQuantity: entryData['quantity'] ?? 0,
              stockCount: entryData['remainingQuantity'] ?? 0,
            ),
          );
        }
      }
    }

    return allBatches;
  }
}
