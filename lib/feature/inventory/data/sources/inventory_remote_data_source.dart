import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gear_track/feature/inventory/data/models/product_model.dart';

abstract class InventoryRemoteDataSource {
  Future<void> addProduct(ProductModel productModel);
  Future<List<ProductModel>> getProducts();
  Future<void> updateProduct(ProductModel productModel);
  Future<void> deleteProduct(String productId);
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
        'quantity': productModel.initialQuantity,
        'remainingQuantity': productModel.stockCount,
        'costCode': productModel.costCode,
      });
    });
  }

  @override
  Future<List<ProductModel>> getProducts() async {
    final productsSnapshot = await firestore.collection('products').get();
    final List<ProductModel> allBatches = [];

    for (final productDoc in productsSnapshot.docs) {
      final productData = productDoc.data();
      final partNo = productData['partNo'] ?? productDoc.id;
      final itemName = productData['itemName'] ?? '';
      final model = productData['model'] ?? '';

      final stockEntriesSnapshot = await productDoc.reference
          .collection('stock_entries')
          .get();
      for (final entryDoc in stockEntriesSnapshot.docs) {
        final entryData = entryDoc.data();
        allBatches.add(
          ProductModel(
            id: entryDoc.id,
            entryDate: (entryData['date'] as Timestamp).toDate(),
            partNo: partNo,
            itemName: itemName,
            model: model,
            costCode: entryData['costCode'] ?? '',
            initialQuantity: entryData['quantity'] ?? 0,
            stockCount: entryData['remainingQuantity'] ?? 0,
          ),
        );
      }
    }
    return allBatches;
  }

  @override
  Future<void> updateProduct(ProductModel productModel) async {
    // productModel.id is the stock entry sub-collection doc ID
    // productModel.partNo is the main product's document ID
    final productRef = firestore
        .collection('products')
        .doc(productModel.partNo);
    final entryRef = productRef
        .collection('stock_entries')
        .doc(productModel.id);

    await firestore.runTransaction((transaction) async {
      final entrySnapshot = await transaction.get(entryRef);
      int oldRemaining = 0;
      if (entrySnapshot.exists) {
        oldRemaining = entrySnapshot.data()?['remainingQuantity'] ?? 0;
      }

      // Update core details in main product
      transaction.update(productRef, {
        'itemName': productModel.itemName,
        'model': productModel.model,
      });

      // Update specific batch details in sub-collection
      transaction.update(entryRef, {
        'date': Timestamp.fromDate(productModel.entryDate),
        'remainingQuantity': productModel.stockCount,
        'costCode': productModel.costCode,
      });

      // Adjust main product's total stock count based on the update difference
      final productSnapshot = await transaction.get(productRef);
      if (productSnapshot.exists) {
        final productData = productSnapshot.data() ?? {};
        final int currentTotalStock = productData['totalStock'] ?? 0;
        final int diff = productModel.stockCount - oldRemaining;
        final int newTotalStock = currentTotalStock + diff;

        transaction.update(productRef, {'totalStock': newTotalStock});
      }
    });
  }

  @override
  Future<void> deleteProduct(String productId) async {
    // Search for the stock entry across all products using collectionGroup
    final querySnapshot = await firestore
        .collectionGroup('stock_entries')
        .where(FieldPath.documentId, isEqualTo: productId)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'not-found',
        message: 'Stock entry batch not found with ID: $productId',
      );
    }

    final entryDoc = querySnapshot.docs.first;
    final entryRef = entryDoc.reference;
    final productRef = entryRef.parent.parent!;
    final int remainingQuantity = entryDoc.data()['remainingQuantity'] ?? 0;

    await firestore.runTransaction((transaction) async {
      final productSnapshot = await transaction.get(productRef);
      if (productSnapshot.exists) {
        final productData = productSnapshot.data() ?? {};
        final int currentTotalStock = productData['totalStock'] ?? 0;
        final int newTotalStock = (currentTotalStock - remainingQuantity)
            .clamp(0, double.infinity)
            .toInt();

        transaction.update(productRef, {'totalStock': newTotalStock});
      }
      transaction.delete(entryRef);
    });
  }
}
