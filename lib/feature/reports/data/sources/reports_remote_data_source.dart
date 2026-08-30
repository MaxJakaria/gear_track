import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../feature/inventory/data/models/product_model.dart';
import '../../../../feature/product_of_sales/data/models/sale_model.dart';

abstract class ReportsRemoteDataSource {
  Future<List<SaleModel>> getAllSales();
  Future<List<ProductModel>> getAllProducts();
}

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  final FirebaseFirestore firestore;

  ReportsRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<SaleModel>> getAllSales() async {
    try {
      final snapshot = await firestore
          .collectionGroup('sales_records')
          .orderBy('saleDate', descending: true)
          .get();

      return snapshot.docs.map((doc) => SaleModel.fromFirestore(doc)).toList();
    } catch (e) {
      // Fallback if collectionGroup index is building or not present
      final salesDocSnapshot = await firestore.collection('sales').get();
      final List<SaleModel> allSales = [];

      for (final doc in salesDocSnapshot.docs) {
        final subSnapshot = await doc.reference
            .collection('sales_records')
            .orderBy('saleDate', descending: true)
            .get();
        for (final saleDoc in subSnapshot.docs) {
          allSales.add(SaleModel.fromFirestore(saleDoc));
        }
      }
      return allSales;
    }
  }

  @override
  Future<List<ProductModel>> getAllProducts() async {
    final productsSnapshot = await firestore.collection('products').get();
    final List<ProductModel> allBatches = [];

    for (final productDoc in productsSnapshot.docs) {
      final productData = productDoc.data();
      final defaultPartNo = productData['partNo'] ?? productDoc.id;
      final itemName = productData['itemName'] ?? '';
      final model = productData['model'] ?? '';
      final totalStock = (productData['totalStock'] as num?)?.toInt() ?? 0;

      final stockEntriesSnapshot =
          await productDoc.reference.collection('stock_entries').get();

      if (stockEntriesSnapshot.docs.isEmpty) {
        // Direct product entry without batches
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
        for (final entryDoc in stockEntriesSnapshot.docs) {
          final entryData = entryDoc.data();
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
