import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gear_track/feature/receipt_verification/data/models/invoice_model.dart';

abstract class ReceiptVerificationRemoteDataSource {
  Future<InvoiceModel?> getInvoice(String invoiceId);
}

class ReceiptVerificationRemoteDataSourceImpl
    implements ReceiptVerificationRemoteDataSource {
  final FirebaseFirestore firestore;

  ReceiptVerificationRemoteDataSourceImpl({required this.firestore});

  @override
  Future<InvoiceModel?> getInvoice(String invoiceId) async {
    final cleanId = invoiceId.trim();
    if (cleanId.isEmpty) return null;

    final doc = await firestore.collection('invoices').doc(cleanId).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return InvoiceModel.fromFirestore(doc);
  }
}
