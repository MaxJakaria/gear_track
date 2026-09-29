import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gear_track/feature/receipt_verification/data/models/invoice_model.dart';
import 'package:gear_track/feature/returns/data/models/return_model.dart';
import 'package:gear_track/feature/returns/domain/entities/return_entity.dart';

/// Data transfer object holding paginated return models and server aggregation statistics.
class PaginatedReturnsResponse {
  final List<ReturnModel> returns;
  final int totalCount;
  final double totalRefundsAllTime;
  final int totalItemsReturnedAllTime;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  const PaginatedReturnsResponse({
    required this.returns,
    required this.totalCount,
    required this.totalRefundsAllTime,
    required this.totalItemsReturnedAllTime,
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
  });
}

/// Contract for handling return operations and Firestore transaction synchronizations.
abstract class ReturnRemoteDataSource {
  /// Processes a customer return, updates invoice status, and restores inventory stock.
  Future<ReturnModel> processReturn(ReturnModel returnModel);

  /// Retrieves a paginated slice of returns directly from Firestore with limit and cursors.
  Future<PaginatedReturnsResponse> getReturns({
    int page = 1,
    int pageSize = 10,
  });

  /// Fetches the details of an existing customer invoice by its unique ID.
  Future<InvoiceModel> getInvoiceForReturn(String invoiceId);

  /// Searches invoices strictly by Customer Name (partyName) or Invoice ID (invoiceId).
  Future<List<InvoiceModel>> searchInvoicesForReturn(String query);
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
  final Map<int, DocumentSnapshot> _lastDocOfPage = {};
  int _cachedTotalCount = 0;
  double _cachedTotalRefunds = 0.0;
  int _cachedTotalItems = 0;

  ReturnRemoteDataSourceImpl({required this.firestore});

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
    // Invalidate pagination cache so newly processed return appears on page 1
    _lastDocOfPage.clear();
    _cachedTotalCount = 0;

    // 1. Pre-resolve restocking targets outside the transaction
    final restockItems = returnModel.items.where((i) => i.restock).toList();
    final resolvedItems = await Future.wait(
      restockItems.map(_resolveRestockItem),
    );

    // 2. Pre-fetch invoice to get product IDs and pre-fetch sales records per product subcollection
    final invoiceRef = firestore
        .collection('invoices')
        .doc(returnModel.invoiceId);
    final invoicePreSnap = await invoiceRef.get();
    if (!invoicePreSnap.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'not-found',
        message: 'Invoice not found: ${returnModel.invoiceId}',
      );
    }

    final invoicePreData = invoicePreSnap.data() ?? {};
    final rawInvoiceItems = invoicePreData['items'] as List<dynamic>? ?? [];

    final Set<String> targetProductIds = {};
    for (final raw in rawInvoiceItems) {
      if (raw is Map) {
        final pId = (raw['productId'] ?? '').toString().trim();
        if (pId.isNotEmpty) {
          targetProductIds.add(pId.contains('/') ? pId.split('/')[0] : pId);
        }
      }
    }
    for (final r in resolvedItems) {
      targetProductIds.add(r.productRef.id);
    }

    // Fetch all sales records for this invoice using collectionGroup (with fallback to subcollections)
    final List<DocumentSnapshot<Map<String, dynamic>>> allSalesDocs = [];
    try {
      final groupSnap = await firestore
          .collectionGroup('sales_records')
          .where('invoiceId', isEqualTo: returnModel.invoiceId)
          .get();
      allSalesDocs.addAll(groupSnap.docs);
    } catch (_) {}

    if (allSalesDocs.isEmpty) {
      for (final pId in targetProductIds) {
        try {
          final pSalesSnap = await firestore
              .collection('sales')
              .doc(pId)
              .collection('sales_records')
              .where('invoiceId', isEqualTo: returnModel.invoiceId)
              .get();
          for (final doc in pSalesSnap.docs) {
            if (!allSalesDocs.any((d) => d.reference.path == doc.reference.path)) {
              allSalesDocs.add(doc);
            }
          }
        } catch (_) {}
      }
    }

    await firestore.runTransaction((transaction) async {
      // -----------------------------------------------------------------------
      // Step 1: READ - Fetch and validate the original customer invoice
      // -----------------------------------------------------------------------
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

      // Read sales records inside transaction
      final Map<String, DocumentSnapshot<Map<String, dynamic>>> salesDocSnaps =
          {};
      for (final doc in allSalesDocs) {
        final snap = await transaction.get(doc.reference);
        if (snap.exists) {
          salesDocSnaps[doc.reference.path] = snap;
        }
      }

      // -----------------------------------------------------------------------
      // Step 3: COMPUTE - Update returned and active remaining invoice items
      // -----------------------------------------------------------------------
      final invoiceData = invoiceSnap.data() ?? {};
      final rawItems = invoiceData['items'] as List<dynamic>? ?? [];
      final remainingReturns = returnModel.items
          .map(
            (i) => {
              'batchId': i.batchId,
              'partNo': i.partNo,
              'productId': i.productId,
              'qty': i.quantity,
            },
          )
          .toList();

      final List<Map<String, dynamic>> activeInvoiceItems = [];

      for (final raw in rawItems) {
        final item = Map<String, dynamic>.from(raw as Map);
        final origSoldQty = (item['quantity'] as num?)?.toInt() ?? 0;
        final curReturnedQty = (item['returnedQuantity'] as num?)?.toInt() ?? 0;
        final availableToReturn =
            (origSoldQty - curReturnedQty).clamp(0, origSoldQty);

        final bId = (item['batchId'] ?? '').toString();
        final pNo = (item['partNo'] ?? '').toString();
        final pId = (item['productId'] ?? '').toString();
        final itemName = (item['itemName'] ?? '').toString();

        // Match by batchId (preferred), partNo, productId, or itemName
        final matchIdx = remainingReturns.indexWhere(
          (r) =>
              (bId.isNotEmpty && r['batchId'] == bId ||
                  pNo.isNotEmpty && r['partNo'] == pNo ||
                  pId.isNotEmpty && r['productId'] == pId ||
                  (itemName.isNotEmpty && r['itemName'] == itemName)) &&
              (r['qty'] as int) > 0,
        );

        int returnQty = 0;
        if (matchIdx != -1) {
          final ret = remainingReturns[matchIdx];
          final req = ret['qty'] as int;
          returnQty = req > availableToReturn ? availableToReturn : req;
          ret['qty'] = req - returnQty;
        }

        final newReturnedQty = curReturnedQty + returnQty;
        final remainingAvailable = origSoldQty - newReturnedQty;

        item['quantity'] = origSoldQty; // Preserve original sold quantity
        final unitPrice = (item['sellPrice'] as num?)?.toDouble() ?? 0.0;
        item['subtotal'] = remainingAvailable * unitPrice;
        item['returnedQuantity'] = newReturnedQty;
        item['returnableQuantity'] = remainingAvailable;
        activeInvoiceItems.add(item);
      }

      final bool isFullReturn = activeInvoiceItems.every(
        (i) => ((i['returnableQuantity'] as num?)?.toInt() ?? 0) <= 0,
      );

      // Compute sales records quantity updates (zeroing returned amounts instead of deleting)
      final Map<DocumentReference, int> salesToUpdate = {};

      final remainingSalesReturns = returnModel.items
          .map(
            (i) => {
              'batchId': i.batchId,
              'partNo': i.partNo,
              'productId': i.productId,
              'itemName': i.itemName,
              'qty': i.quantity,
            },
          )
          .toList();

      for (final doc in allSalesDocs) {
        final sData =
            salesDocSnaps[doc.reference.path]?.data() ?? doc.data();
        if (sData == null) continue;
        final curQty = (sData['quantity'] as num?)?.toInt() ?? 0;
        final sBatchId = (sData['batchId'] ?? '').toString();
        final sPartNo = (sData['partNo'] ?? '').toString();
        final sProductId = (sData['productId'] ?? '').toString();
        final sItemName = (sData['itemName'] ?? '').toString();

        final matchIdx = remainingSalesReturns.indexWhere(
          (r) =>
              (sBatchId.isNotEmpty && r['batchId'] == sBatchId ||
                  sPartNo.isNotEmpty && r['partNo'] == sPartNo ||
                  sProductId.isNotEmpty && r['productId'] == sProductId ||
                  (sItemName.isNotEmpty && r['itemName'] == sItemName)) &&
              (r['qty'] as int) > 0,
        );

        int retQty = 0;
        if (matchIdx != -1) {
          final ret = remainingSalesReturns[matchIdx];
          final req = ret['qty'] as int;
          retQty = req > curQty ? curQty : req;
          ret['qty'] = req - retQty;
        }

        if (retQty > 0 || isFullReturn) {
          final newQty = isFullReturn && retQty == 0 && remainingSalesReturns.isEmpty
              ? 0
              : (curQty - retQty).clamp(0, double.infinity).toInt();
          salesToUpdate[doc.reference] = newQty;
        }
      }

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

      // B. Update invoice with remaining active items and return status
      final double newTotalAmount = activeInvoiceItems.fold<double>(
        0.0,
        (acc, i) => acc + ((i['subtotal'] as num?)?.toDouble() ?? 0.0),
      );
      final int newTotalItems = activeInvoiceItems.fold<int>(
        0,
        (acc, i) => acc + ((i['returnableQuantity'] as num?)?.toInt() ?? 0),
      );

      transaction.update(invoiceRef, {
        'items': activeInvoiceItems,
        'totalAmount': newTotalAmount,
        'totalItems': newTotalItems,
        'returnedAmount':
            ((invoiceData['returnedAmount'] as num?)?.toDouble() ?? 0.0) +
            returnModel.totalRefundAmount,
        'returnStatus': isFullReturn ? 'FULL' : 'PARTIAL',
        'lastReturnDate': Timestamp.fromDate(returnModel.returnDate),
      });

      // C. Update matching sales records
      for (final entry in salesToUpdate.entries) {
        transaction.update(entry.key, {'quantity': entry.value});
      }

      // D. Update totalStock in the parent 'products' collection
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

      // E. Restock batch quantities in the 'stock_entries' subcollection
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
  Future<PaginatedReturnsResponse> getReturns({
    int page = 1,
    int pageSize = 10,
  }) async {
    // 1. Refresh server-side total count on page 1 or if uninitialized
    if (page == 1 || _cachedTotalCount == 0) {
      _lastDocOfPage.clear();
      try {
        final countSnap = await firestore.collection('returns').count().get();
        _cachedTotalCount = countSnap.count ?? 0;
      } catch (_) {}
    }

    // 2. Query Firestore with cursor and limit
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = [];
    if (page == 1) {
      final snapshot = await firestore
          .collection('returns')
          .orderBy('returnDate', descending: true)
          .limit(pageSize)
          .get();
      docs = snapshot.docs;
      if (docs.isNotEmpty) {
        _lastDocOfPage[1] = docs.last;
      }
    } else {
      final prevDoc = _lastDocOfPage[page - 1];
      if (prevDoc != null) {
        final snapshot = await firestore
            .collection('returns')
            .orderBy('returnDate', descending: true)
            .startAfterDocument(prevDoc)
            .limit(pageSize)
            .get();
        docs = snapshot.docs;
        if (docs.isNotEmpty) {
          _lastDocOfPage[page] = docs.last;
        }
      } else {
        // Fallback if previous page boundary isn't cached:
        final snapshot = await firestore
            .collection('returns')
            .orderBy('returnDate', descending: true)
            .limit(page * pageSize)
            .get();
        for (int i = 0; i < page; i++) {
          final endIdx = ((i + 1) * pageSize) - 1;
          if (endIdx < snapshot.docs.length) {
            _lastDocOfPage[i + 1] = snapshot.docs[endIdx];
          } else if (snapshot.docs.isNotEmpty) {
            _lastDocOfPage[i + 1] = snapshot.docs.last;
          }
        }
        final startIndex = (page - 1) * pageSize;
        if (startIndex < snapshot.docs.length) {
          docs = snapshot.docs.sublist(
            startIndex,
            (startIndex + pageSize).clamp(0, snapshot.docs.length),
          );
        }
      }
    }

    final returnModels =
        docs.map((doc) => ReturnModel.fromFirestore(doc)).toList();

    // Compute metrics on page 1
    if (page == 1 || _cachedTotalRefunds == 0.0) {
      _cachedTotalRefunds =
          returnModels.fold(0.0, (s, r) => s + r.totalRefundAmount);
      _cachedTotalItems = returnModels.fold(0, (s, r) => s + r.totalQuantity);
    }

    if (_cachedTotalCount == 0 && docs.isNotEmpty) {
      _cachedTotalCount = docs.length;
    }

    final totalPages = _cachedTotalCount <= 0
        ? 1
        : (_cachedTotalCount / pageSize).ceil();

    return PaginatedReturnsResponse(
      returns: returnModels,
      totalCount: _cachedTotalCount,
      totalRefundsAllTime: _cachedTotalRefunds,
      totalItemsReturnedAllTime: _cachedTotalItems,
      currentPage: page,
      totalPages: totalPages,
      hasMore: page < totalPages,
    );
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

  @override
  Future<List<InvoiceModel>> searchInvoicesForReturn(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    final List<InvoiceModel> results = [];
    final Set<String> processedInvoiceIds = {};

    // 1. Exact document ID lookup
    try {
      final doc =
          await firestore.collection('invoices').doc(query.trim()).get();
      if (doc.exists) {
        final model = InvoiceModel.fromFirestore(doc);
        if (!model.isFullyReturned && model.remainingReturnableItems > 0) {
          results.add(model);
          processedInvoiceIds.add(model.invoiceId);
        }
      }
    } catch (_) {}

    // 2. Query recent invoices ordered by saleDate descending with fallback
    try {
      final snapshot = await firestore
          .collection('invoices')
          .orderBy('saleDate', descending: true)
          .limit(200)
          .get();

      for (final doc in snapshot.docs) {
        if (processedInvoiceIds.contains(doc.id)) continue;
        final model = InvoiceModel.fromFirestore(doc);

        // Strictly matches Customer Name (partyName) or Invoice ID (invoiceId)
        final bool invoiceIdMatches =
            model.invoiceId.toLowerCase().contains(cleanQuery);
        final bool customerNameMatches =
            model.partyName.toLowerCase().contains(cleanQuery);

        if (invoiceIdMatches || customerNameMatches) {
          // Exclude invoices where all items have already been returned
          if (!model.isFullyReturned && model.remainingReturnableItems > 0) {
            results.add(model);
            processedInvoiceIds.add(model.invoiceId);
          }
        }
      }
    } catch (_) {
      try {
        final snapshot =
            await firestore.collection('invoices').limit(200).get();
        for (final doc in snapshot.docs) {
          if (processedInvoiceIds.contains(doc.id)) continue;
          final model = InvoiceModel.fromFirestore(doc);

          final bool invoiceIdMatches =
              model.invoiceId.toLowerCase().contains(cleanQuery);
          final bool customerNameMatches =
              model.partyName.toLowerCase().contains(cleanQuery);

          if (invoiceIdMatches || customerNameMatches) {
            if (!model.isFullyReturned && model.remainingReturnableItems > 0) {
              results.add(model);
              processedInvoiceIds.add(model.invoiceId);
            }
          }
        }
      } catch (_) {}
    }

    return results;
  }
}
