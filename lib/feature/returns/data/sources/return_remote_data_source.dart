import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gear_track/feature/receipt_verification/data/models/invoice_model.dart';
import 'package:gear_track/feature/returns/data/models/return_model.dart';
import 'package:gear_track/feature/returns/domain/entities/return_entity.dart';

/// Contract for handling return operations and Firestore transaction synchronizations.
abstract class ReturnRemoteDataSource {
  /// Processes a customer return, updates invoice status, and restores inventory stock.
  Future<ReturnModel> processReturn(ReturnModel returnModel);

  /// Retrieves the history of all processed returns ordered by date.
  Future<List<ReturnModel>> getReturns();

  /// Fetches the details of an existing customer invoice by its unique ID.
  Future<InvoiceModel> getInvoiceForReturn(String invoiceId);
}

/// Internal lightweight record to bundle an item with its Firestore product and batch references.
typedef _RestockItem = ({
  ReturnItemEntity item,
  DocumentReference<Map<String, dynamic>> productRef,
  DocumentReference<Map<String, dynamic>> batchRef,
});

/// Implementation of [ReturnRemoteDataSource] backed by Firebase Cloud Firestore.
class ReturnRemoteDataSourceImpl implements ReturnRemoteDataSource {
  final FirebaseFirestore firestore;

  const ReturnRemoteDataSourceImpl({required this.firestore});

  // ---------------------------------------------------------------------------
  // Reference Resolution Helpers
  // ---------------------------------------------------------------------------

  /// Resolves the exact Firestore DocumentReference for both the parent product and its batch.
  /// Uses a multi-tier lookup (batch ID -> part number -> auto-generate new batch) to guarantee
  /// restocking targets are always valid even for older or imported receipts.
  Future<_RestockItem> _resolveRestockItem(ReturnItemEntity item) async {
    final rawId = item.productId.trim().isNotEmpty
        ? item.productId.trim()
        : item.partNo.trim();
    final docId = rawId.contains('/') ? rawId.split('/')[0] : rawId;
    var batchId = item.batchId.trim();

    // Extract batch ID if embedded in composite format (e.g., 'productId/batchId')
    if (batchId.isEmpty && rawId.contains('/')) {
      batchId = rawId.split('/')[1].trim();
    }

    // 1. Locate the parent product document in the 'products' collection
    var productRef = firestore.collection('products').doc(docId);
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
      } else {
        // Fallback: search across all subcollections via collectionGroup
        final queryBatch = await firestore
            .collectionGroup('stock_entries')
            .where('partNo', isEqualTo: lookupPart)
            .limit(1)
            .get();
        if (queryBatch.docs.isNotEmpty) {
          final parentDocId = queryBatch.docs.first.reference.parent.parent?.id;
          if (parentDocId != null && parentDocId.isNotEmpty) {
            productRef = firestore.collection('products').doc(parentDocId);
            if (batchId.isEmpty) batchId = queryBatch.docs.first.id;
          }
        }
      }
    }

    // 2. Locate the specific batch document inside the product's 'stock_entries' subcollection
    DocumentReference<Map<String, dynamic>>? batchRef;
    if (batchId.isNotEmpty) {
      final candidateRef = productRef.collection('stock_entries').doc(batchId);
      final batchSnap = await candidateRef.get();
      if (batchSnap.exists) batchRef = candidateRef;
    }

    // Fallback: match by part number under this product if candidate batch was missing
    if (batchRef == null && item.partNo.isNotEmpty) {
      final bQuery = await productRef
          .collection('stock_entries')
          .where('partNo', isEqualTo: item.partNo)
          .limit(1)
          .get();
      if (bQuery.docs.isNotEmpty) batchRef = bQuery.docs.first.reference;
    }

    // Ultimate fallback: if product currently has no recorded batches, generate a new batch ID
    batchRef ??= productRef
        .collection('stock_entries')
        .doc('${DateTime.now().millisecondsSinceEpoch}_RET');

    return (item: item, productRef: productRef, batchRef: batchRef);
  }

  // ---------------------------------------------------------------------------
  // Return Processing (Single Atomic Transaction)
  // ---------------------------------------------------------------------------

  @override
  Future<ReturnModel> processReturn(ReturnModel returnModel) async {
    // Pre-resolve restocking targets outside the transaction to avoid async queries inside it
    final restockItems = returnModel.items.where((i) => i.restock).toList();
    final resolvedItems = await Future.wait(
      restockItems.map(_resolveRestockItem),
    );

    await firestore.runTransaction((transaction) async {
      // -----------------------------------------------------------------------
      // Step 1: READ - Fetch and validate the original customer invoice
      // -----------------------------------------------------------------------
      final invoiceRef = firestore
          .collection('invoices')
          .doc(returnModel.invoiceId);
      final invoiceSnap = await transaction.get(invoiceRef);
      if (!invoiceSnap.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Invoice not found: ${returnModel.invoiceId}',
        );
      }

      // -----------------------------------------------------------------------
      // Step 2: READ - Fetch target product and batch documents (all reads first)
      // -----------------------------------------------------------------------
      final Map<String, int> productStocks = {};
      final Map<String, DocumentSnapshot<Map<String, dynamic>>> productSnaps =
          {};
      for (final r in resolvedItems) {
        final pId = r.productRef.id;
        if (!productSnaps.containsKey(pId)) {
          final snap = await transaction.get(r.productRef);
          productSnaps[pId] = snap;
          productStocks[pId] = snap.exists
              ? (snap.data()?['totalStock'] as num?)?.toInt() ?? 0
              : 0;
        }
      }

      final Map<String, int> batchStocks = {};
      final Map<String, int> batchInitials = {};
      final Map<String, DocumentSnapshot<Map<String, dynamic>>> batchSnaps = {};
      for (final r in resolvedItems) {
        final path = r.batchRef.path;
        if (!batchSnaps.containsKey(path)) {
          final snap = await transaction.get(r.batchRef);
          batchSnaps[path] = snap;
          batchStocks[path] = snap.exists
              ? (snap.data()?['remainingQuantity'] as num?)?.toInt() ?? 0
              : 0;
          batchInitials[path] = snap.exists
              ? (snap.data()?['quantity'] as num?)?.toInt() ?? 0
              : 0;
        }
      }

      // -----------------------------------------------------------------------
      // Step 3: COMPUTE - Update returned and returnable quantities on invoice items
      // -----------------------------------------------------------------------
      final invoiceData = invoiceSnap.data() ?? {};
      final rawItems = invoiceData['items'] as List<dynamic>? ?? [];
      final remainingReturns = returnModel.items
          .map(
            (i) => {
              'batchId': i.batchId,
              'partNo': i.partNo,
              'qty': i.quantity,
            },
          )
          .toList();

      final List<Map<String, dynamic>> updatedItems = [];
      for (final raw in rawItems) {
        final item = Map<String, dynamic>.from(raw as Map);
        final origQty = (item['quantity'] as num?)?.toInt() ?? 0;
        final prevReturned = (item['returnedQuantity'] as num?)?.toInt() ?? 0;
        final maxReturnable = (origQty - prevReturned).clamp(0, origQty);

        final bId = (item['batchId'] ?? '').toString();
        final pNo = (item['partNo'] ?? '').toString();

        // Match by batchId (preferred) or partNo
        final matchIdx = remainingReturns.indexWhere(
          (r) =>
              (bId.isNotEmpty && r['batchId'] == bId || r['partNo'] == pNo) &&
              (r['qty'] as int) > 0,
        );

        int returnQty = 0;
        if (matchIdx != -1) {
          final ret = remainingReturns[matchIdx];
          final req = ret['qty'] as int;
          returnQty = req > maxReturnable ? maxReturnable : req;
          ret['qty'] = req - returnQty;
        }

        final newReturned = prevReturned + returnQty;
        item['returnedQuantity'] = newReturned;
        item['returnableQuantity'] = (origQty - newReturned).clamp(0, origQty);
        updatedItems.add(item);
      }

      // Determine new overall invoice return status: FULL, PARTIAL, or NONE
      final totalOrig = updatedItems.fold<int>(
        0,
        (t, i) => t + ((i['quantity'] as num?)?.toInt() ?? 0),
      );
      final totalRet = updatedItems.fold<int>(
        0,
        (t, i) => t + ((i['returnedQuantity'] as num?)?.toInt() ?? 0),
      );
      final returnStatus = (totalOrig > 0 && totalRet >= totalOrig)
          ? 'FULL'
          : (totalRet > 0 ? 'PARTIAL' : 'NONE');
      final newRefundAmount =
          ((invoiceData['returnedAmount'] as num?)?.toDouble() ?? 0.0) +
          returnModel.totalRefundAmount;

      // -----------------------------------------------------------------------
      // Step 4: COMPUTE - Calculate stock increments for products and batches
      // -----------------------------------------------------------------------
      final Map<DocumentReference<Map<String, dynamic>>, int> batchUpdates = {};
      for (final r in resolvedItems) {
        final pId = r.productRef.id;
        productStocks[pId] = (productStocks[pId] ?? 0) + r.item.quantity;

        final path = r.batchRef.path;
        final newBatchQty = (batchStocks[path] ?? 0) + r.item.quantity;
        batchStocks[path] = newBatchQty;
        batchUpdates[r.batchRef] = newBatchQty;
      }

      // -----------------------------------------------------------------------
      // Step 5: WRITE - Execute atomic database commits (all writes after reads)
      // -----------------------------------------------------------------------

      // A. Save the new return record in the 'returns' collection
      transaction.set(
        firestore.collection('returns').doc(returnModel.returnId),
        returnModel.toMap(),
      );

      // B. Update invoice items, cumulative refund total, and return status
      transaction.update(invoiceRef, {
        'items': updatedItems,
        'returnedAmount': newRefundAmount,
        'returnStatus': returnStatus,
        'lastReturnDate': Timestamp.fromDate(returnModel.returnDate),
      });

      // C. Update totalStock in the parent 'products' collection
      for (final entry in productStocks.entries) {
        final ref = firestore.collection('products').doc(entry.key);
        if (productSnaps[entry.key]?.exists == true) {
          transaction.update(ref, {'totalStock': entry.value});
        } else {
          final sample = resolvedItems
              .firstWhere((r) => r.productRef.id == entry.key)
              .item;
          transaction.set(ref, {
            'partNo': sample.partNo,
            'itemName': sample.itemName,
            'model': '',
            'costCode': sample.costCode,
            'totalStock': entry.value,
            'entryDate': Timestamp.fromDate(returnModel.returnDate),
          }, SetOptions(merge: true));
        }
      }

      // D. Restock batch quantities in the 'stock_entries' subcollection
      for (final entry in batchUpdates.entries) {
        final path = entry.key.path;
        final newStock = entry.value;
        final snap = batchSnaps[path];

        if (snap?.exists == true) {
          final oldInitial = batchInitials[path] ?? 0;
          transaction.update(entry.key, {
            'remainingQuantity': newStock,
            if (newStock > oldInitial) 'quantity': newStock,
          });
        } else {
          // If this is a newly created batch entry document, set all fields
          final sample = resolvedItems
              .firstWhere((r) => r.batchRef.path == path)
              .item;
          transaction.set(entry.key, {
            'date': Timestamp.fromDate(returnModel.returnDate),
            'partNo': sample.partNo,
            'quantity': newStock,
            'remainingQuantity': newStock,
            'costCode': sample.costCode,
          });
        }
      }
    });

    return returnModel;
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

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
