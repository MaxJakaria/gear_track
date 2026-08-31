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
    // We use partNo as the unique ID for the main product document, fallback to model id
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
          id: entryDoc.id,
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
    DocumentReference<Map<String, dynamic>> productRef = firestore
        .collection('products')
        .doc(productModel.partNo);
    DocumentReference<Map<String, dynamic>> entryRef = productRef
        .collection('stock_entries')
        .doc(productModel.id);

    // 1. Locate the actual entry document and parent productRef
    final directCheck = await entryRef.get();
    if (!directCheck.exists) {
      final allEntries = await firestore.collectionGroup('stock_entries').get();
      final matching = allEntries.docs
          .where((d) => d.id == productModel.id)
          .toList();
      if (matching.isNotEmpty) {
        entryRef = matching.first.reference;
        productRef = entryRef.parent.parent!;
      }
    }

    // 2. Fetch all sibling batches under this parent product to calculate exact totalStock
    final siblingEntriesSnapshot = await productRef
        .collection('stock_entries')
        .get();

    await firestore.runTransaction((transaction) async {
      // 1. ALL READS FIRST (Strict Firestore transaction rule)
      final entrySnapshot = await transaction.get(entryRef);
      final productSnapshot = await transaction.get(productRef);

      final List<int> siblingStocks = [];
      for (final doc in siblingEntriesSnapshot.docs) {
        if (doc.id == productModel.id) continue;
        final snap = await transaction.get(doc.reference);
        if (snap.exists) {
          final data = snap.data();
          if (data is Map<String, dynamic>) {
            siblingStocks.add(
              (data['remainingQuantity'] as num?)?.toInt() ?? 0,
            );
          }
        }
      }

      // Calculate the true totalStock across all batches of this product
      int trueTotalStock = productModel.stockCount;
      for (final s in siblingStocks) {
        trueTotalStock += s;
      }

      // 2. ALL WRITES AFTER
      if (productSnapshot.exists) {
        transaction.update(productRef, {
          'itemName': productModel.itemName,
          'model': productModel.model,
          'partNo': productModel.partNo,
          'totalStock': trueTotalStock,
        });
      }

      if (entrySnapshot.exists) {
        final data = entrySnapshot.data();
        int oldInitial = 0;
        if (data is Map<String, dynamic>) {
          oldInitial = (data['quantity'] as num?)?.toInt() ?? 0;
        }
        final int newInitial = productModel.stockCount > oldInitial
            ? productModel.stockCount
            : (productModel.initialQuantity > 0
                  ? productModel.initialQuantity
                  : oldInitial);

        transaction.update(entryRef, {
          'date': Timestamp.fromDate(productModel.entryDate),
          'partNo': productModel.partNo,
          'quantity': newInitial,
          'remainingQuantity': productModel.stockCount,
          'costCode': productModel.costCode,
        });
      }
    });
  }

  @override
  Future<void> deleteProduct(String productId) async {
    // 1. Search across stock entries for matching batch ID
    final querySnapshot = await firestore
        .collectionGroup('stock_entries')
        .get();
    final matchingDocs = querySnapshot.docs
        .where((doc) => doc.id == productId)
        .toList();

    if (matchingDocs.isNotEmpty) {
      final entryDoc = matchingDocs.first;
      final entryRef = entryDoc.reference;
      final productRef = entryRef.parent.parent!;

      // Fetch all remaining sibling batches under parent product
      final siblingEntriesSnapshot = await productRef
          .collection('stock_entries')
          .get();

      await firestore.runTransaction((transaction) async {
        // ALL READS FIRST
        final productSnapshot = await transaction.get(productRef);
        final entrySnapshot = await transaction.get(entryRef);

        final List<int> siblingStocks = [];
        for (final doc in siblingEntriesSnapshot.docs) {
          if (doc.id == productId) continue;
          final snap = await transaction.get(doc.reference);
          if (snap.exists) {
            final data = snap.data();
            if (data is Map<String, dynamic>) {
              siblingStocks.add(
                (data['remainingQuantity'] as num?)?.toInt() ?? 0,
              );
            }
          }
        }

        int trueTotalStock = 0;
        for (final s in siblingStocks) {
          trueTotalStock += s;
        }

        // ALL WRITES AFTER
        if (productSnapshot.exists) {
          transaction.update(productRef, {'totalStock': trueTotalStock});
        }

        if (entrySnapshot.exists) {
          transaction.delete(entryRef);
        }
      });
      return;
    }

    // 2. Check if productId directly matches a main product document
    final directProductRef = firestore.collection('products').doc(productId);
    final directSnapshot = await directProductRef.get();
    if (directSnapshot.exists) {
      final entries = await directProductRef.collection('stock_entries').get();
      final batch = firestore.batch();
      for (final entry in entries.docs) {
        batch.delete(entry.reference);
      }
      batch.delete(directProductRef);
      await batch.commit();
    }
  }

  @override
  Future<void> clearAllProducts() async {
    final batch = firestore.batch();

    final stockEntries = await firestore.collectionGroup('stock_entries').get();
    for (final doc in stockEntries.docs) {
      batch.delete(doc.reference);
    }

    final products = await firestore.collection('products').get();
    for (final doc in products.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
