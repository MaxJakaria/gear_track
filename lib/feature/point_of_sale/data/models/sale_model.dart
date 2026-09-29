import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/sale_entity.dart';

class SaleModel extends SaleEntity {
  const SaleModel({
    required super.id,
    required super.productId,
    super.batchId = '',
    super.partNo = '',
    required super.saleDate,
    required super.itemName,
    required super.quantity,
    required super.sellPrice,
    required super.costCode,
    super.invoiceId = '',
    super.partyName = '',
    super.partyAddress = '',
    super.servedBy = '',
  });

  factory SaleModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SaleModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      batchId: data['batchId'] ?? '',
      partNo: data['partNo'] ?? '',
      saleDate: (data['saleDate'] as Timestamp).toDate(),
      itemName: data['itemName'] ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      sellPrice: (data['sellPrice'] as num?)?.toDouble() ?? 0.0,
      costCode: data['costCode'] ?? '',
      invoiceId: data['invoiceId'] ?? '',
      partyName: data['partyName'] ?? '',
      partyAddress: data['partyAddress'] ?? '',
      servedBy: data['servedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'batchId': batchId,
      'partNo': partNo,
      'saleDate': Timestamp.fromDate(saleDate),
      'itemName': itemName,
      'quantity': quantity,
      'sellPrice': sellPrice,
      'costCode': costCode,
      'invoiceId': invoiceId,
      'partyName': partyName,
      'partyAddress': partyAddress,
      'servedBy': servedBy,
    };
  }

  factory SaleModel.fromEntity(SaleEntity saleEntity) {
    return SaleModel(
      id: saleEntity.id,
      productId: saleEntity.productId,
      batchId: saleEntity.batchId,
      partNo: saleEntity.partNo,
      saleDate: saleEntity.saleDate,
      itemName: saleEntity.itemName,
      quantity: saleEntity.quantity,
      sellPrice: saleEntity.sellPrice,
      costCode: saleEntity.costCode,
      invoiceId: saleEntity.invoiceId,
      partyName: saleEntity.partyName,
      partyAddress: saleEntity.partyAddress,
      servedBy: saleEntity.servedBy,
    );
  }
}
