import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gear_track/feature/point_of_sale/data/models/sale_model.dart';
import 'package:gear_track/feature/receipt_verification/data/models/invoice_model.dart';

abstract class PosRemoteDataSource {
  Future<void> addSale(SaleModel saleModel);
  Future<void> checkoutCart({
    required List<SaleModel> sales,
    required InvoiceModel invoice,
  });
  Future<List<SaleModel>> getSales();
  Future<List<SaleModel>> getProductSales(String productId);
  Future<void> saveInvoice(InvoiceModel invoiceModel);
}

class _ResolvedCartItem {
  final SaleModel sale;
  final DocumentReference<Map<String, dynamic>> productRef;
  final DocumentReference<Map<String, dynamic>>? batchRef;

  _ResolvedCartItem({
    required this.sale,
    required this.productRef,
    this.batchRef,
  });
}

class PosRemoteDataSourceImpl implements PosRemoteDataSource {
  final FirebaseFirestore firestore;

  PosRemoteDataSourceImpl({required this.firestore});

  /// Direct O(1) in-memory resolution for product and batch references
  _ResolvedCartItem _resolveCartItem(SaleModel sale) {
    final docId = sale.partNo.isNotEmpty ? sale.partNo : sale.productId;
    final productRef = firestore.collection('products').doc(docId);
    final batchRef = sale.batchId.isNotEmpty
        ? productRef.collection('stock_entries').doc(sale.batchId)
        : null;

    return _ResolvedCartItem(
      sale: sale,
      productRef: productRef,
      batchRef: batchRef,
    );
  }

  @override
  Future<void> checkoutCart({
    required List<SaleModel> sales,
    required InvoiceModel invoice,
  }) async {
    if (sales.isEmpty) return;

    // 1. Direct O(1) in-memory resolution of all items
    final resolvedItems = sales.map(_resolveCartItem).toList();

    // 2. Run Single Atomic Transaction for the Entire Checkout
    await firestore.runTransaction((transaction) async {
      // Step A: READ - Get all unique product documents
      final Map<String, DocumentSnapshot<Map<String, dynamic>>> productSnapshots = {};
      final Map<String, int> productTotalStocks = {};

      for (final item in resolvedItems) {
        final pId = item.productRef.id;
        if (!productSnapshots.containsKey(pId)) {
          final snap = await transaction.get(item.productRef);
          if (!snap.exists) {
            throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'not-found',
              message: 'Product document not found: $pId',
            );
          }
          productSnapshots[pId] = snap;
          final pData = snap.data() ?? {};
          productTotalStocks[pId] =
              (pData['totalStock'] as num?)?.toInt() ?? 0;
        }
      }

      // Step B: READ - Get all batch documents
      final Map<String, DocumentSnapshot<Map<String, dynamic>>> batchSnapshots = {};
      final Map<String, int> batchRemainingStocks = {};

      for (final item in resolvedItems) {
        if (item.batchRef != null) {
          final bPath = item.batchRef!.path;
          if (!batchSnapshots.containsKey(bPath)) {
            final snap = await transaction.get(item.batchRef!);
            if (snap.exists) {
              batchSnapshots[bPath] = snap;
              final bData = snap.data() ?? {};
              batchRemainingStocks[bPath] =
                  (bData['remainingQuantity'] as num?)?.toInt() ?? 0;
            }
          }
        }
      }

      // Step C: Validate stock & compute deductions in memory
      final List<MapEntry<DocumentReference<Map<String, dynamic>>, int>> batchUpdates = [];
      final Map<String, int> finalProductStocks = Map.from(productTotalStocks);

      for (final item in resolvedItems) {
        final pId = item.productRef.id;
        final currentProdStock = finalProductStocks[pId] ?? 0;

        if (currentProdStock < item.sale.quantity) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'out-of-range',
            message:
                'Insufficient total stock for "${item.sale.itemName}". Available: $currentProdStock, Requested: ${item.sale.quantity}',
          );
        }

        finalProductStocks[pId] = currentProdStock - item.sale.quantity;

        if (item.batchRef != null) {
          final bPath = item.batchRef!.path;
          final currentBatchStock = batchRemainingStocks[bPath] ?? 0;
          if (currentBatchStock < item.sale.quantity) {
            throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'out-of-range',
              message:
                  'Insufficient batch stock for "${item.sale.itemName}". Available: $currentBatchStock, Requested: ${item.sale.quantity}',
            );
          }
          final newBatchStock = currentBatchStock - item.sale.quantity;
          batchRemainingStocks[bPath] = newBatchStock;
          batchUpdates.add(MapEntry(item.batchRef!, newBatchStock));
        }
      }

      // Step D: ALL WRITES AFTER ALL READS (Single Atomic Commit)
      // 1. Write Invoice
      final invoiceRef =
          firestore.collection('invoices').doc(invoice.invoiceId);
      transaction.set(invoiceRef, invoice.toMap(), SetOptions(merge: true));

      // 2. Write Batch stock updates
      for (final update in batchUpdates) {
        transaction.update(update.key, {'remainingQuantity': update.value});
      }

      // 3. Write Product totalStock updates
      for (final entry in finalProductStocks.entries) {
        final pRef = firestore.collection('products').doc(entry.key);
        transaction.update(pRef, {'totalStock': entry.value});
      }

      // 4. Write Individual Sales Records
      for (final item in resolvedItems) {
        final pId = item.productRef.id;
        final salesProductRef =
            firestore.collection('sales').doc(pId);
        transaction.set(
          salesProductRef,
          {
            'productId': pId,
            'itemName': item.sale.itemName,
            'lastSaleDate': Timestamp.fromDate(item.sale.saleDate),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        final saleRecordRef =
            salesProductRef.collection('sales_records').doc(item.sale.id);
        transaction.set(saleRecordRef, item.sale.toMap());
      }
    });
  }

  @override
  Future<void> addSale(SaleModel saleModel) async {
    final item = _resolveCartItem(saleModel);

    await firestore.runTransaction((transaction) async {
      final productSnap = await transaction.get(item.productRef);
      if (!productSnap.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Product document not found: ${item.productRef.id}',
        );
      }

      final productData = productSnap.data() ?? {};
      final int currentTotalStock =
          (productData['totalStock'] as num?)?.toInt() ?? 0;

      if (currentTotalStock < saleModel.quantity) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'out-of-range',
          message:
              'Insufficient stock for "${saleModel.itemName}". Available: $currentTotalStock, Sold: ${saleModel.quantity}',
        );
      }

      if (item.batchRef != null) {
        final batchSnap = await transaction.get(item.batchRef!);
        if (batchSnap.exists) {
          final batchData = batchSnap.data() ?? {};
          final int batchRemaining =
              (batchData['remainingQuantity'] as num?)?.toInt() ?? 0;
          if (batchRemaining < saleModel.quantity) {
            throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'out-of-range',
              message:
                  'Insufficient batch stock for "${saleModel.itemName}". Available: $batchRemaining, Sold: ${saleModel.quantity}',
            );
          }
          transaction.update(
            item.batchRef!,
            {'remainingQuantity': batchRemaining - saleModel.quantity},
          );
        }
      }

      // Update product total stock
      transaction.update(
        item.productRef,
        {'totalStock': currentTotalStock - saleModel.quantity},
      );

      // Save sale records
      final salesProductRef =
          firestore.collection('sales').doc(item.productRef.id);
      transaction.set(
        salesProductRef,
        {
          'productId': item.productRef.id,
          'itemName': saleModel.itemName,
          'lastSaleDate': Timestamp.fromDate(saleModel.saleDate),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final saleRecordRef =
          salesProductRef.collection('sales_records').doc(saleModel.id);
      transaction.set(saleRecordRef, saleModel.toMap());
    });
  }

  @override
  Future<List<SaleModel>> getSales() async {
    final snapshot = await firestore.collectionGroup('sales_records').get();
    return snapshot.docs.map((doc) => SaleModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<SaleModel>> getProductSales(String productId) async {
    final snapshot = await firestore
        .collection('sales')
        .doc(productId)
        .collection('sales_records')
        .orderBy('saleDate', descending: true)
        .get();

    return snapshot.docs.map((doc) => SaleModel.fromFirestore(doc)).toList();
  }

  @override
  Future<void> saveInvoice(InvoiceModel invoiceModel) async {
    await firestore
        .collection('invoices')
        .doc(invoiceModel.invoiceId)
        .set(invoiceModel.toMap(), SetOptions(merge: true));
  }
}
