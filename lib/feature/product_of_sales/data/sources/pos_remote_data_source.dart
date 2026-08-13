import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gear_track/feature/product_of_sales/data/models/sale_model.dart';

abstract class PosRemoteDataSource {
  Future<void> addSale(SaleModel saleModel);
  Future<List<SaleModel>> getSales();
}

class PosRemoteDataSourceImpl implements PosRemoteDataSource {
  final FirebaseFirestore firestore;

  PosRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> addSale(SaleModel saleModel) async {
    final productId = saleModel.productId;
    final int soldQuantity = saleModel.quantity;

    // Fetch the stock entries (sub-collection) ordered by date ascending for FIFO
    final stockEntriesSnapshot = await firestore
        .collection('products')
        .doc(productId)
        .collection('stock_entries')
        .orderBy('date', descending: false)
        .get();

    await firestore.runTransaction((transaction) async {
      // 1. READ: Get main product document inside transaction
      final productRef = firestore.collection('products').doc(productId);
      final productSnapshot = await transaction.get(productRef);

      if (!productSnapshot.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Product not found with ID: $productId',
        );
      }

      final productData = productSnapshot.data() ?? {};
      final int currentTotalStock = productData['totalStock'] ?? 0;

      if (currentTotalStock < soldQuantity) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'out-of-range',
          message: 'Insufficient product total stock. Available: $currentTotalStock, Sold: $soldQuantity',
        );
      }

      // 2. READ: Fetch all candidate batch document snapshots FIRST before any writes.
      // Firestore transactions strictly enforce that all reads must occur before any writes.
      final activeDocs = stockEntriesSnapshot.docs.where((doc) {
        final data = doc.data();
        final remaining = data['remainingQuantity'] ?? 0;
        return (remaining as num) > 0;
      }).toList();

      final List<MapEntry<DocumentReference, int>> batchStates = [];
      int totalAvailableInBatches = 0;

      for (final doc in activeDocs) {
        final entrySnapshot = await transaction.get(doc.reference);
        if (entrySnapshot.exists) {
          final entryData = entrySnapshot.data() ?? {};
          final int remaining = entryData['remainingQuantity'] ?? 0;
          if (remaining > 0) {
            batchStates.add(MapEntry(doc.reference, remaining));
            totalAvailableInBatches += remaining;
          }
        }
      }

      if (totalAvailableInBatches < soldQuantity) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'out-of-range',
          message: 'Insufficient stock in active batches. Total remaining: $totalAvailableInBatches, Sold: $soldQuantity',
        );
      }

      // 3. LOGIC: Calculate FIFO stock deductions in memory
      int remainingToDeduct = soldQuantity;
      final List<MapEntry<DocumentReference, int>> batchUpdates = [];

      for (final batch in batchStates) {
        if (remainingToDeduct <= 0) break;

        final ref = batch.key;
        final currentRem = batch.value;

        if (currentRem >= remainingToDeduct) {
          batchUpdates.add(MapEntry(ref, currentRem - remainingToDeduct));
          remainingToDeduct = 0;
        } else {
          remainingToDeduct -= currentRem;
          batchUpdates.add(MapEntry(ref, 0));
        }
      }

      if (remainingToDeduct > 0) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'aborted',
          message: 'FIFO stock deduction failed. Could not satisfy quantity: $soldQuantity',
        );
      }

      // 4. WRITE: Perform all batch updates
      for (final update in batchUpdates) {
        transaction.update(update.key, {'remainingQuantity': update.value});
      }

      // 5. WRITE: Update main product document's totalStock
      final int newTotalStock = currentTotalStock - soldQuantity;
      transaction.update(productRef, {
        'totalStock': newTotalStock,
      });

      // 6. WRITE: Save sale record into sales collection
      final saleRef = firestore.collection('sales').doc(saleModel.id);
      transaction.set(saleRef, saleModel.toMap());
    });
  }

  @override
  Future<List<SaleModel>> getSales() async {
    final snapshot = await firestore.collection('sales').get();
    return snapshot.docs.map((doc) => SaleModel.fromFirestore(doc)).toList();
  }
}
