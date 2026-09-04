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

  /// Direct O(1) in-memory resolution with dynamic fallback for restocking product and batch references
  Future<_ResolvedRestockItem> _resolveRestockItemAsync(ReturnItemEntity item) async {
    final rawId = item.productId.trim().isNotEmpty
        ? item.productId.trim()
        : item.partNo.trim();
    final docId = rawId.contains('/') ? rawId.split('/')[0] : rawId;
    var productRef = firestore.collection('products').doc(docId);
    DocumentReference<Map<String, dynamic>>? batchRef = item.batchId.isNotEmpty
        ? productRef.collection('stock_entries').doc(item.batchId)
        : null;

    final checkSnap = await productRef.get();
    if (!checkSnap.exists) {
      final lookupPart = item.partNo.isNotEmpty ? item.partNo : docId;
      final queryByPart = await firestore
          .collection('products')
          .where('partNo', isEqualTo: lookupPart)
          .limit(1)
          .get();

      if (queryByPart.docs.isNotEmpty) {
        productRef = queryByPart.docs.first.reference;
        if (item.batchId.isNotEmpty) {
          batchRef = productRef.collection('stock_entries').doc(item.batchId);
        }
      } else {
        final queryBatch = await firestore
            .collectionGroup('stock_entries')
            .where('partNo', isEqualTo: lookupPart)
            .limit(1)
            .get();

        if (queryBatch.docs.isNotEmpty) {
          final entryDoc = queryBatch.docs.first;
          final parentDocId = entryDoc.reference.parent.parent?.id;
          if (parentDocId != null && parentDocId.isNotEmpty) {
            productRef = firestore.collection('products').doc(parentDocId);
            batchRef = entryDoc.reference;
          }
        }
      }
    } else if (batchRef != null) {
      final batchSnap = await batchRef.get();
      if (!batchSnap.exists && item.partNo.isNotEmpty) {
        final bQuery = await productRef
            .collection('stock_entries')
            .where('partNo', isEqualTo: item.partNo)
            .limit(1)
            .get();
        if (bQuery.docs.isNotEmpty) {
          batchRef = bQuery.docs.first.reference;
        }
      }
    }

    return _ResolvedRestockItem(
      item: item,
      productRef: productRef,
      batchRef: batchRef,
    );
  }

  @override
  Future<ReturnModel> processReturn(ReturnModel returnModel) async {
    // 1. Resolve restock items with dynamic fallback
    final restockItems = returnModel.items.where((i) => i.restock).toList();
    final resolvedRestockItems =
        await Future.wait(restockItems.map(_resolveRestockItemAsync));

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

      // Track remaining return item quantities so identical products aren't double-counted
      final remainingReturnItems = returnModel.items
          .map((i) => {
                'productId': i.productId,
                'batchId': i.batchId,
                'partNo': i.partNo,
                'quantity': i.quantity,
                'itemName': i.itemName,
              })
          .toList();

      // Check return quantities against invoice item remaining returnable quantities
      for (int i = 0; i < rawItems.length; i++) {
        final itemMap = Map<String, dynamic>.from(rawItems[i] as Map);
        final itemProdId = itemMap['productId'] ?? '';
        final itemBatchId = itemMap['batchId'] ?? '';
        final itemPartNo = itemMap['partNo'] ?? '';
        final int originalQty = (itemMap['quantity'] as num?)?.toInt() ?? 0;
        final int prevReturnedQty =
            (itemMap['returnedQuantity'] as num?)?.toInt() ?? 0;
        final int maxAvailableToReturn =
            (originalQty - prevReturnedQty).clamp(0, originalQty);

        int returnQtyForThisItem = 0;

        // Find match in remainingReturnItems (prioritize batchId, then partNo, then productId)
        int matchIdx = -1;
        if (itemBatchId.toString().isNotEmpty) {
          matchIdx = remainingReturnItems.indexWhere((r) =>
              (r['batchId'] as String?) == itemBatchId &&
              (r['quantity'] as int) > 0);
        }
        if (matchIdx == -1 && itemPartNo.toString().isNotEmpty) {
          matchIdx = remainingReturnItems.indexWhere((r) =>
              (r['partNo'] as String?) == itemPartNo &&
              (r['quantity'] as int) > 0);
        }
        if (matchIdx == -1 && itemProdId.toString().isNotEmpty) {
          matchIdx = remainingReturnItems.indexWhere((r) =>
              (r['productId'] as String?) == itemProdId &&
              (r['quantity'] as int) > 0);
        }

        if (matchIdx != -1) {
          final retItem = remainingReturnItems[matchIdx];
          final requestedQty = retItem['quantity'] as int;
          final toDeduct = requestedQty > maxAvailableToReturn
              ? maxAvailableToReturn
              : requestedQty;
          returnQtyForThisItem = toDeduct;
          retItem['quantity'] = requestedQty - toDeduct;
        }

        final newReturnedQty = prevReturnedQty + returnQtyForThisItem;
        itemMap['returnedQuantity'] = newReturnedQty;
        itemMap['returnableQuantity'] = originalQty - newReturnedQty;

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
      final int totalOriginalCount = updatedInvoiceItems.fold<int>(
        0,
        (acc, item) => acc + ((item['quantity'] as num?)?.toInt() ?? 0),
      );
      final int totalReturnedCount = updatedInvoiceItems.fold<int>(
        0,
        (acc, item) =>
            acc + ((item['returnedQuantity'] as num?)?.toInt() ?? 0),
      );
      final bool allFullyReturned = totalOriginalCount > 0 &&
          totalReturnedCount >= totalOriginalCount;
      final String returnStatus = allFullyReturned
          ? 'FULL'
          : (totalReturnedCount > 0 ? 'PARTIAL' : 'NONE');

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
