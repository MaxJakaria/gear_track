import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/sales_record_detail.dart';

class SalesRecordDetailModel extends SalesRecordDetail {
  const SalesRecordDetailModel({
    required super.id,
    required super.saleDate,
    required super.partNo,
    required super.itemName,
    required super.model,
    required super.itemsSold,
    required super.sellPrice,
    required super.costCode,
  });

  factory SalesRecordDetailModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return SalesRecordDetailModel(
      id: id ?? map['id'] ?? '',
      saleDate: (map['saleDate'] is Timestamp)
          ? (map['saleDate'] as Timestamp).toDate()
          : (map['saleDate'] != null
              ? DateTime.tryParse(map['saleDate'].toString()) ?? DateTime.now()
              : DateTime.now()),
      partNo: map['partNo'] ?? '',
      itemName: map['itemName'] ?? '',
      model: map['model'] ?? '',
      itemsSold: (map['itemsSold'] as num?)?.toInt() ?? 0,
      sellPrice: (map['sellPrice'] as num?)?.toDouble() ?? 0.0,
      costCode: map['costCode'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saleDate': Timestamp.fromDate(saleDate),
      'partNo': partNo,
      'itemName': itemName,
      'model': model,
      'itemsSold': itemsSold,
      'sellPrice': sellPrice,
      'costCode': costCode,
    };
  }

  factory SalesRecordDetailModel.fromEntity(SalesRecordDetail entity) {
    return SalesRecordDetailModel(
      id: entity.id,
      saleDate: entity.saleDate,
      partNo: entity.partNo,
      itemName: entity.itemName,
      model: entity.model,
      itemsSold: entity.itemsSold,
      sellPrice: entity.sellPrice,
      costCode: entity.costCode,
    );
  }
}
