import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gear_track/feature/returns/domain/entities/return_entity.dart';

class ReturnItemModel extends ReturnItemEntity {
  const ReturnItemModel({
    required super.productId,
    super.batchId = '',
    required super.itemName,
    required super.partNo,
    required super.quantity,
    required super.sellPrice,
    super.costCode = '',
    super.restock = true,
    super.reason = 'Customer Return',
  });

  factory ReturnItemModel.fromMap(Map<String, dynamic> map) {
    return ReturnItemModel(
      productId: map['productId'] ?? '',
      batchId: map['batchId'] ?? '',
      itemName: map['itemName'] ?? '',
      partNo: map['partNo'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      sellPrice: (map['sellPrice'] as num?)?.toDouble() ?? 0.0,
      costCode: map['costCode'] ?? '',
      restock: map['restock'] as bool? ?? true,
      reason: map['reason'] ?? 'Customer Return',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'batchId': batchId,
      'itemName': itemName,
      'partNo': partNo,
      'quantity': quantity,
      'sellPrice': sellPrice,
      'refundAmount': refundAmount,
      'costCode': costCode,
      'restock': restock,
      'reason': reason,
    };
  }
}

class ReturnModel extends ReturnEntity {
  const ReturnModel({
    required super.returnId,
    required super.invoiceId,
    required super.returnDate,
    required super.totalRefundAmount,
    required super.totalQuantity,
    required super.reason,
    required super.items,
    super.shopName = '',
  });

  factory ReturnModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final rawItems = data['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map(
          (i) => ReturnItemModel.fromMap(Map<String, dynamic>.from(i as Map)),
        )
        .toList();

    DateTime date = DateTime.now();
    if (data['returnDate'] is Timestamp) {
      date = (data['returnDate'] as Timestamp).toDate();
    } else if (data['returnDate'] is String) {
      date = DateTime.tryParse(data['returnDate']) ?? DateTime.now();
    }

    return ReturnModel(
      returnId: doc.id,
      invoiceId: data['invoiceId'] ?? '',
      returnDate: date,
      totalRefundAmount: (data['totalRefundAmount'] as num?)?.toDouble() ?? 0.0,
      totalQuantity: (data['totalQuantity'] as num?)?.toInt() ?? items.length,
      reason: data['reason'] ?? '',
      items: items,
      shopName: data['shopName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'returnId': returnId,
      'invoiceId': invoiceId,
      'returnDate': Timestamp.fromDate(returnDate),
      'formattedDate': formattedDate,
      'formattedTime': formattedTime,
      'totalRefundAmount': totalRefundAmount,
      'totalQuantity': totalQuantity,
      'reason': reason,
      'shopName': shopName,
      'items': items.map((i) {
        if (i is ReturnItemModel) {
          return i.toMap();
        }
        return ReturnItemModel(
          productId: i.productId,
          itemName: i.itemName,
          partNo: i.partNo,
          quantity: i.quantity,
          sellPrice: i.sellPrice,
          costCode: i.costCode,
          restock: i.restock,
          reason: i.reason,
        ).toMap();
      }).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
