import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gear_track/feature/inventory/domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.entryDate,
    required super.partNo,
    required super.itemName,
    required super.model,
    required super.costCode,
    required super.stockCount,
  });

  factory ProductModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ProductModel(
      id: doc.id,
      entryDate: (data['entryDate'] as Timestamp).toDate(),
      partNo: data['partNo'] ?? '',
      itemName: data['itemName'] ?? '',
      model: data['model'] ?? '',
      costCode: data['costCode'] ?? '',
      stockCount: data['stockCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'entryDate': Timestamp.fromDate(entryDate),
      'partNo': partNo,
      'itemName': itemName,
      'model': model,
      'costCode': costCode,
      'stockCount': stockCount,
    };
  }

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      entryDate: product.entryDate,
      partNo: product.partNo,
      itemName: product.itemName,
      model: product.model,
      costCode: product.costCode,
      stockCount: product.stockCount,
    );
  }
}
