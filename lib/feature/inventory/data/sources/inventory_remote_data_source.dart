import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gear_track/feature/inventory/data/models/product_model.dart';

abstract class InventoryRemoteDataSource {
  Future<void> addProduct(ProductModel productModel);
  Future<List<ProductModel>> getProducts();
  Future<void> updateProduct(ProductModel productModel);
  Future<void> deleteProduct(String productId);
  Future<void> clearAllProducts();
}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final FirebaseFirestore firestore;

  InventoryRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> addProduct(ProductModel productModel) async {
    final String docId = productModel.partNo.isNotEmpty
        ? productModel.partNo
        : productModel.id;
    final productRef = firestore.collection('products').doc(docId);

    // Generate a unique ID for the new stock entry batch
    final String entryId =
        '${DateTime.now().millisecondsSinceEpoch}_${productModel.costCode}';
    final entryRef = productRef.collection('stock_entries').doc(entryId);

    await firestore.runTransaction((transaction) async {
      final productSnapshot = await transaction.get(productRef);

      if (!productSnapshot.exists) {
        // Create new main product document if it doesn't exist
        transaction.set(productRef, {
          'entryDate': Timestamp.fromDate(productModel.entryDate),
          'partNo': productModel.partNo,
          'itemName': productModel.itemName,
          'model': productModel.model,
          'costCode': productModel.costCode,
          'totalStock': productModel.stockCount,
        });
      } else {
        // Update total stock in existing main product document
        final data = productSnapshot.data() ?? {};
        final int currentStock = data['totalStock'] ?? 0;
        final int newStock = currentStock + productModel.stockCount;

        transaction.update(productRef, {
          'totalStock': newStock,
          'entryDate': Timestamp.fromDate(
            productModel.entryDate,
          ), // update latest purchase date
          'costCode': productModel.costCode, // update latest cost code
        });
      }

      // Add the new stock entry to the sub-collection
      transaction.set(entryRef, {
        'date': Timestamp.fromDate(productModel.entryDate),
        'partNo': productModel.partNo,
        'quantity': productModel.initialQuantity,
        'remainingQuantity': productModel.stockCount,
        'costCode': productModel.costCode,
      });
    });
  }

  @override
  Future<List<ProductModel>> getProducts() async {
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
    for (final entryDoc in stockEntriesSnapshot.docs) {
      final entryData = entryDoc.data();
      final parentProductId = entryDoc.reference.parent.parent?.id ?? '';
      final productData = productInfoMap[parentProductId] ?? {};

      final defaultPartNo = productData['partNo'] ?? parentProductId;
      final itemName = productData['itemName'] ?? '';
      final model = productData['model'] ?? '';
      final batchPartNo = (entryData['partNo'] as String?)?.isNotEmpty == true
          ? entryData['partNo'] as String
          : defaultPartNo;

      final int remaining =
          (entryData['remainingQuantity'] as num?)?.toInt() ?? 0;
      final int rawInitial = (entryData['quantity'] as num?)?.toInt() ?? 0;
      final int initial = rawInitial <= 0
          ? remaining
          : (rawInitial < remaining ? remaining : rawInitial);

      allBatches.add(
        ProductModel(
          id: parentProductId.isNotEmpty
              ? '$parentProductId/${entryDoc.id}'
              : entryDoc.id,
          entryDate: (entryData['date'] as Timestamp).toDate(),
          partNo: batchPartNo,
          itemName: itemName,
          model: model,
          costCode: entryData['costCode'] ?? '',
          initialQuantity: initial,
          stockCount: remaining,
        ),
      );
    }

    return allBatches;
  }

  @override
  Future<void> updateProduct(ProductModel productModel) async {
    final parts = productModel.id.split('/');
    final productDocId = parts.length == 2 ? parts[0] : productModel.partNo;
    final batchDocId = parts.length == 2 ? parts[1] : productModel.id;

    final productRef = firestore.collection('products').doc(productDocId);
    final entryRef = productRef.collection('stock_entries').doc(batchDocId);

    await firestore.runTransaction((transaction) async {
      // 1. ALL READS FIRST (Direct O(1) - only read the target product and batch)
      final entrySnapshot = await transaction.get(entryRef);
      final productSnapshot = await transaction.get(productRef);

      if (!entrySnapshot.exists) return;

      final entryData = entrySnapshot.data();
      final int oldRemaining =
          (entryData is Map<String, dynamic> ? entryData['remainingQuantity'] as num? : 0)?.toInt() ?? 0;
      final int oldInitial =
          (entryData is Map<String, dynamic> ? entryData['quantity'] as num? : 0)?.toInt() ?? 0;

      // Delta change in stock for this batch
      final int stockDelta = productModel.stockCount - oldRemaining;

      // Calculate new total stock on the parent product
      int newTotalStock = productModel.stockCount;
      if (productSnapshot.exists) {
        final productData = productSnapshot.data();
        final int currentTotal =
            (productData is Map<String, dynamic> ? productData['totalStock'] as num? : 0)?.toInt() ?? 0;
        newTotalStock = (currentTotal + stockDelta).clamp(0, 99999999);
      }

      final int newInitial = productModel.stockCount > oldInitial
          ? productModel.stockCount
          : (productModel.initialQuantity > 0
              ? productModel.initialQuantity
              : oldInitial);

      // 2. ALL WRITES AFTER
      if (productSnapshot.exists) {
        transaction.update(productRef, {
          'itemName': productModel.itemName,
          'model': productModel.model,
          'partNo': productModel.partNo,
          'totalStock': newTotalStock,
        });
      }

      transaction.update(entryRef, {
        'date': Timestamp.fromDate(productModel.entryDate),
        'partNo': productModel.partNo,
        'quantity': newInitial,
        'remainingQuantity': productModel.stockCount,
        'costCode': productModel.costCode,
      });
    });
  }

  @override
  Future<void> deleteProduct(String productId) async {
    final parts = productId.split('/');

    if (parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      // Deleting a specific batch under a product: Direct O(1) transaction
      final productRef = firestore.collection('products').doc(parts[0]);
      final entryRef = productRef.collection('stock_entries').doc(parts[1]);

      await firestore.runTransaction((transaction) async {
        final productSnapshot = await transaction.get(productRef);
        final entrySnapshot = await transaction.get(entryRef);

        if (entrySnapshot.exists) {
          final entryData = entrySnapshot.data();
          final int batchRemaining =
              (entryData is Map<String, dynamic> ? entryData['remainingQuantity'] as num? : 0)?.toInt() ?? 0;

          if (productSnapshot.exists) {
            final productData = productSnapshot.data();
            final int currentTotal =
                (productData is Map<String, dynamic> ? productData['totalStock'] as num? : 0)?.toInt() ?? 0;
            final int newTotal = (currentTotal - batchRemaining).clamp(0, 99999999);
            transaction.update(productRef, {'totalStock': newTotal});
          }

          transaction.delete(entryRef);
        }
      });
    } else {
      // Deleting entire product and its stock entries in parallel
      final productRef = firestore.collection('products').doc(productId);
      final entries = await productRef.collection('stock_entries').get();
      final batch = firestore.batch();
      for (final entry in entries.docs) {
        batch.delete(entry.reference);
      }
      batch.delete(productRef);
      await batch.commit();
    }
  }

  @override
  Future<void> clearAllProducts() async {
    final results = await Future.wait([
      firestore.collectionGroup('stock_entries').get(),
      firestore.collection('products').get(),
    ]);

    final allDocs = [...results[0].docs, ...results[1].docs];
    if (allDocs.isEmpty) return;

    // Commit in chunks of 400 to adhere to Firestore limits safely
    for (int i = 0; i < allDocs.length; i += 400) {
      final end = (i + 400 < allDocs.length) ? i + 400 : allDocs.length;
      final batch = firestore.batch();
      for (int j = i; j < end; j++) {
        batch.delete(allDocs[j].reference);
      }
      await batch.commit();
    }
  }
}
