import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/sale_entity.dart';

class SaleModel extends SaleEntity {
  const SaleModel({
    required super.id,
    required super.productId,
    required super.saleDate,
    required super.itemName,
    required super.quantity,
    required super.sellPrice,
    required super.costCode,
  });

  factory SaleModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SaleModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      saleDate: (data['saleDate'] as Timestamp).toDate(),
      itemName: data['itemName'] ?? '',
      quantity: data['quantity'] ?? 0,
      sellPrice: (data['sellPrice'] ?? 0.0).toDouble(),
      costCode: data['costCode'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'saleDate': Timestamp.fromDate(saleDate),
      'itemName': itemName,
      'quantity': quantity,
      'sellPrice': sellPrice,
      'costCode': costCode,
    };
  }

  factory SaleModel.fromEntity(SaleEntity saleEntity) {
    return SaleModel(
      id: saleEntity.id,
      productId: saleEntity.productId,
      saleDate: saleEntity.saleDate,
      itemName: saleEntity.itemName,
      quantity: saleEntity.quantity,
      sellPrice: saleEntity.sellPrice,
      costCode: saleEntity.costCode,
    );
  }
}
