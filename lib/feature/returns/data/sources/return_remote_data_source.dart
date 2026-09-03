import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gear_track/feature/receipt_verification/data/models/invoice_model.dart';
import 'package:gear_track/feature/returns/data/models/return_model.dart';
import 'package:gear_track/feature/returns/domain/entities/return_entity.dart';

abstract class ReturnRemoteDataSource {
  Future<ReturnModel> processReturn(ReturnModel returnModel);
  Future<List<ReturnModel>> getReturns();
  Future<InvoiceModel> getInvoiceForReturn(String invoiceId);
}

class _ResolvedRestockItem {
  final ReturnItemEntity item;
  final DocumentReference<Map<String, dynamic>> productRef;
  final DocumentReference<Map<String, dynamic>>? batchRef;

  _ResolvedRestockItem({
    required this.item,
    required this.productRef,
    this.batchRef,
  });
}

class ReturnRemoteDataSourceImpl implements ReturnRemoteDataSource {
  final FirebaseFirestore firestore;

  ReturnRemoteDataSourceImpl({required this.firestore});

  /// Direct O(1) in-memory resolution for restocking product and batch references
  _ResolvedRestockItem _resolveRestockItem(ReturnItemEntity item) {
    final docId = item.partNo.isNotEmpty ? item.partNo : item.productId;
    final productRef = firestore.collection('products').doc(docId);
    final batchRef = item.batchId.isNotEmpty
        ? productRef.collection('stock_entries').doc(item.batchId)
        : null;

    return _ResolvedRestockItem(
      item: item,
      productRef: productRef,
      batchRef: batchRef,
    );
  }

  @override
  Future<ReturnModel> processReturn(ReturnModel returnModel) async {
    // 1. Resolve restock items directly in O(1) time
    final resolvedRestockItems = returnModel.items
        .where((i) => i.restock)
        .map(_resolveRestockItem)
        .toList();

    // 2. Run single atomic transaction
    await firestore.runTransaction((transaction) async {
      // Step A: Read Invoice
      final invoiceRef =
          firestore.collection('invoices').doc(returnModel.invoiceId);
      final invoiceSnap = await transaction.get(invoiceRef);

      if (!invoiceSnap.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Invoice not found: ${returnModel.invoiceId}',
        );
      }

      final invoiceData = invoiceSnap.data() ?? {};
      final rawItems = invoiceData['items'] as List<dynamic>? ?? [];
      final List<Map<String, dynamic>> updatedInvoiceItems = [];

      final currentReturnedAmount =
          (invoiceData['returnedAmount'] as num?)?.toDouble() ?? 0.0;

      // Check return quantities against invoice item remaining returnable quantities
      for (final raw in rawItems) {
        final itemMap = Map<String, dynamic>.from(raw as Map);
        final itemProdId = itemMap['productId'] ?? '';
        final itemPartNo = itemMap['partNo'] ?? '';
        final int originalQty = (itemMap['quantity'] as num?)?.toInt() ?? 0;
        final int prevReturnedQty =
            (itemMap['returnedQuantity'] as num?)?.toInt() ?? 0;

        // Find if this item is in the current return
        final matchingReturn = returnModel.items.firstWhere(
          (r) =>
              (r.productId.isNotEmpty && r.productId == itemProdId) ||
              (r.partNo.isNotEmpty && r.partNo == itemPartNo),
          orElse: () => const ReturnItemModel(
            productId: '',
            itemName: '',
            partNo: '',
            quantity: 0,
            sellPrice: 0.0,
          ),
        );

        if (matchingReturn.quantity > 0) {
          final newReturnedQty = prevReturnedQty + matchingReturn.quantity;
          if (newReturnedQty > originalQty) {
            throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'out-of-range',
              message:
                  'Cannot return ${matchingReturn.quantity} units of "${matchingReturn.itemName}". '
                  'Purchased: $originalQty, Already returned: $prevReturnedQty.',
            );
          }
          itemMap['returnedQuantity'] = newReturnedQty;
          itemMap['returnableQuantity'] = originalQty - newReturnedQty;
        }

        updatedInvoiceItems.add(itemMap);
      }

      // Step B: Read Product and Batch documents for restock items
      final Map<String, DocumentSnapshot<Map<String, dynamic>>> productSnapshots = {};
      final Map<String, int> productStocks = {};

      for (final rItem in resolvedRestockItems) {
        final pId = rItem.productRef.id;
        if (!productSnapshots.containsKey(pId)) {
          final snap = await transaction.get(rItem.productRef);
          if (snap.exists) {
            productSnapshots[pId] = snap;
            productStocks[pId] =
                (snap.data()?['totalStock'] as num?)?.toInt() ?? 0;
          }
        }
      }

      final Map<String, DocumentSnapshot<Map<String, dynamic>>> batchSnapshots = {};
      final Map<String, int> batchStocks = {};

      for (final rItem in resolvedRestockItems) {
        if (rItem.batchRef != null) {
          final bPath = rItem.batchRef!.path;
          if (!batchSnapshots.containsKey(bPath)) {
            final snap = await transaction.get(rItem.batchRef!);
            if (snap.exists) {
              batchSnapshots[bPath] = snap;
              batchStocks[bPath] =
                  (snap.data()?['remainingQuantity'] as num?)?.toInt() ?? 0;
            }
          }
        }
      }

      // Step C: Compute stock additions
      final Map<String, int> finalProductStocks = Map.from(productStocks);
      final Map<DocumentReference<Map<String, dynamic>>, int> batchUpdates = {};

      for (final rItem in resolvedRestockItems) {
        final pId = rItem.productRef.id;
        if (finalProductStocks.containsKey(pId)) {
          finalProductStocks[pId] =
              (finalProductStocks[pId] ?? 0) + rItem.item.quantity;
        }

        if (rItem.batchRef != null) {
          final bPath = rItem.batchRef!.path;
          if (batchStocks.containsKey(bPath)) {
            final newBatchStock =
                (batchStocks[bPath] ?? 0) + rItem.item.quantity;
            batchStocks[bPath] = newBatchStock;
            batchUpdates[rItem.batchRef!] = newBatchStock;
          }
        }
      }

      // Step D: Calculate Invoice status
      final newReturnedAmount =
          currentReturnedAmount + returnModel.totalRefundAmount;
      final bool allFullyReturned = updatedInvoiceItems.every((item) {
        final q = (item['quantity'] as num?)?.toInt() ?? 0;
        final r = (item['returnedQuantity'] as num?)?.toInt() ?? 0;
        return r >= q;
      });
      final String returnStatus = allFullyReturned ? 'FULL' : 'PARTIAL';

      // Step E: Atomic Writes (All writes after all reads)
      // 1. Write Return Document
      final returnRef =
          firestore.collection('returns').doc(returnModel.returnId);
      transaction.set(returnRef, returnModel.toMap());

      // 2. Update Invoice
      transaction.update(invoiceRef, {
        'items': updatedInvoiceItems,
        'returnedAmount': newReturnedAmount,
        'returnStatus': returnStatus,
        'lastReturnDate': Timestamp.fromDate(returnModel.returnDate),
      });

      // 3. Update Product Total Stocks
      for (final entry in finalProductStocks.entries) {
        final pRef = firestore.collection('products').doc(entry.key);
        transaction.update(pRef, {'totalStock': entry.value});
      }

      // 4. Update Batch Stocks
      for (final entry in batchUpdates.entries) {
        transaction.update(entry.key, {'remainingQuantity': entry.value});
      }
    });

    return returnModel;
  }

  @override
  Future<List<ReturnModel>> getReturns() async {
    final snapshot = await firestore
        .collection('returns')
        .orderBy('returnDate', descending: true)
        .get();

    return snapshot.docs.map((doc) => ReturnModel.fromFirestore(doc)).toList();
  }

  @override
  Future<InvoiceModel> getInvoiceForReturn(String invoiceId) async {
    final cleanId = invoiceId.trim();
    final doc = await firestore.collection('invoices').doc(cleanId).get();

    if (!doc.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'not-found',
        message: 'No invoice found with ID: $cleanId',
      );
    }

    return InvoiceModel.fromFirestore(doc);
  }
}
