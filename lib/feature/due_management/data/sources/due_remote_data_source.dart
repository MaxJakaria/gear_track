import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gear_track/feature/receipt_verification/data/models/invoice_model.dart';

abstract class DueRemoteDataSource {
  Future<List<InvoiceModel>> getDueInvoices();
  Future<InvoiceModel> collectDuePayment(String invoiceId, double paymentAmount);
}

class DueRemoteDataSourceImpl implements DueRemoteDataSource {
  final FirebaseFirestore firestore;

  DueRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<InvoiceModel>> getDueInvoices() async {
    final querySnapshot = await firestore
        .collection('invoices')
        .where('dueAmount', isGreaterThan: 0)
        .get();

    final invoices = querySnapshot.docs
        .map((doc) => InvoiceModel.fromFirestore(doc))
        .toList();

    // Sort newest first
    invoices.sort((a, b) => b.saleDate.compareTo(a.saleDate));
    return invoices;
  }

  @override
  Future<InvoiceModel> collectDuePayment(
    String invoiceId,
    double paymentAmount,
  ) async {
    final docRef = firestore.collection('invoices').doc(invoiceId);

    return firestore.runTransaction<InvoiceModel>((transaction) async {
      final docSnap = await transaction.get(docRef);
      if (!docSnap.exists) {
        throw Exception('Invoice $invoiceId not found');
      }

      final data = docSnap.data()!;
      final currentDue = ((data['dueAmount'] as num?)?.toDouble() ?? 0.0);
      final currentPaid = ((data['paidAmount'] as num?)?.toDouble() ?? 0.0);
      final totalAmount = ((data['totalAmount'] as num?)?.toDouble() ?? 0.0);

      if (paymentAmount <= 0) {
        throw Exception('Payment amount must be greater than zero');
      }

      final effectivePayment = paymentAmount > currentDue ? currentDue : paymentAmount;
      final newDue = (currentDue - effectivePayment).clamp(0.0, totalAmount);
      final newPaid = currentPaid + effectivePayment;
      final newPaymentStatus = newDue <= 0.001 ? 'PAID' : 'PARTIAL';

      final historyList = List<Map<String, dynamic>>.from(
        (data['paymentHistory'] as List<dynamic>?) ?? [],
      );
      historyList.add({
        'amount': effectivePayment,
        'date': Timestamp.now(),
        'previousDue': currentDue,
        'remainingDue': newDue,
      });

      transaction.update(docRef, {
        'dueAmount': newDue,
        'paidAmount': newPaid,
        'paymentStatus': newPaymentStatus,
        'paymentHistory': historyList,
        'lastPaymentDate': Timestamp.now(),
      });

      // Fetch updated data locally
      final updatedData = Map<String, dynamic>.from(data);
      updatedData['dueAmount'] = newDue;
      updatedData['paidAmount'] = newPaid;
      updatedData['paymentStatus'] = newPaymentStatus;
      updatedData['paymentHistory'] = historyList;
      updatedData['lastPaymentDate'] = Timestamp.now();

      return InvoiceModel.fromMap(updatedData, invoiceId);
    });
  }
}
