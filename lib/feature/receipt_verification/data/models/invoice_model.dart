import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gear_track/core/entities/shop_settings.dart';
import 'package:gear_track/feature/point_of_sale/domain/entities/cart_item.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';

class InvoiceItemModel extends InvoiceItemEntity {
  const InvoiceItemModel({
    required super.productId,
    super.batchId = '',
    required super.itemName,
    required super.partNo,
    required super.quantity,
    required super.sellPrice,
    super.costCode = '',
    super.returnedQuantity = 0,
  });

  factory InvoiceItemModel.fromCartItem(CartItem item) {
    return InvoiceItemModel(
      productId: item.productId,
      batchId: item.batchId,
      itemName: item.itemName,
      partNo: item.partNo,
      quantity: item.quantity,
      sellPrice: item.sellPrice,
      costCode: item.costCode,
      returnedQuantity: 0,
    );
  }

  factory InvoiceItemModel.fromMap(Map<String, dynamic> map) {
    return InvoiceItemModel(
      productId: map['productId'] ?? '',
      batchId: map['batchId'] ?? '',
      itemName: map['itemName'] ?? '',
      partNo: map['partNo'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      sellPrice: (map['sellPrice'] as num?)?.toDouble() ?? 0.0,
      costCode: map['costCode'] ?? '',
      returnedQuantity: (map['returnedQuantity'] as num?)?.toInt() ?? 0,
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
      'costCode': costCode,
      'subtotal': subtotal,
      'returnedQuantity': returnedQuantity,
      'returnableQuantity': returnableQuantity,
    };
  }
}

class InvoiceModel extends InvoiceEntity {
  const InvoiceModel({
    required super.invoiceId,
    required super.saleDate,
    required super.totalAmount,
    required super.totalItems,
    required super.items,
    super.shopName = '',
    super.shopPhone = '',
    super.shopAddress = '',
    super.shopEmail = '',
    super.partyName = '',
    super.partyAddress = '',
    super.servedBy = '',
    super.returnedAmount = 0.0,
    super.returnStatus = 'NONE',
    super.paidAmount,
    super.dueAmount,
    super.paymentStatus,
  });

  factory InvoiceModel.fromCartItems({
    required String invoiceId,
    required DateTime saleDate,
    required List<CartItem> cartItems,
    ShopSettings shopSettings = const ShopSettings(),
    String partyName = '',
    String partyAddress = '',
    String servedBy = '',
    double? paidAmount,
    double? dueAmount,
    String? paymentStatus,
  }) {
    final items = cartItems
        .map((i) => InvoiceItemModel.fromCartItem(i))
        .toList();
    final totalAmount = items.fold<double>(
      0.0,
      (accTotal, i) => accTotal + i.subtotal,
    );
    final totalItems = items.fold<int>(
      0,
      (accCount, i) => accCount + i.quantity,
    );

    return InvoiceModel(
      invoiceId: invoiceId,
      saleDate: saleDate,
      totalAmount: totalAmount,
      totalItems: totalItems,
      items: items,
      shopName: shopSettings.shopName,
      shopPhone: shopSettings.phone,
      shopAddress: shopSettings.address,
      shopEmail: shopSettings.email,
      partyName: partyName,
      partyAddress: partyAddress,
      servedBy: servedBy,
      returnedAmount: 0.0,
      returnStatus: 'NONE',
      paidAmount: paidAmount ?? totalAmount,
      dueAmount: dueAmount ?? 0.0,
      paymentStatus: paymentStatus,
    );
  }

  factory InvoiceModel.fromEntity(InvoiceEntity entity) {
    return InvoiceModel(
      invoiceId: entity.invoiceId,
      saleDate: entity.saleDate,
      totalAmount: entity.totalAmount,
      totalItems: entity.totalItems,
      items: entity.items,
      shopName: entity.shopName,
      shopPhone: entity.shopPhone,
      shopAddress: entity.shopAddress,
      shopEmail: entity.shopEmail,
      partyName: entity.partyName,
      partyAddress: entity.partyAddress,
      servedBy: entity.servedBy,
      returnedAmount: entity.returnedAmount,
      returnStatus: entity.returnStatus,
      paidAmount: entity.paidAmount,
      dueAmount: entity.dueAmount,
      paymentStatus: entity.paymentStatus,
    );
  }

  factory InvoiceModel.fromMap(
    Map<String, dynamic> data,
    String invoiceId,
  ) {
    final rawItems = data['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map(
          (i) => InvoiceItemModel.fromMap(Map<String, dynamic>.from(i as Map)),
        )
        .toList();

    DateTime date = DateTime.now();
    if (data['saleDate'] is Timestamp) {
      date = (data['saleDate'] as Timestamp).toDate();
    } else if (data['saleDate'] is String) {
      date = DateTime.tryParse(data['saleDate']) ?? DateTime.now();
    }

    final totalAmt = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final paidAmt = (data['paidAmount'] as num?)?.toDouble() ?? totalAmt;
    final dueAmt = (data['dueAmount'] as num?)?.toDouble() ?? 0.0;
    final payStatus = data['paymentStatus'] as String? ??
        (dueAmt > 0 ? (paidAmt > 0 ? 'PARTIAL' : 'DUE') : 'PAID');

    return InvoiceModel(
      invoiceId: invoiceId,
      saleDate: date,
      totalAmount: totalAmt,
      totalItems: (data['totalItems'] as num?)?.toInt() ?? items.length,
      items: items,
      shopName: data['shopName'] ?? '',
      shopPhone: data['shopPhone'] ?? '',
      shopAddress: data['shopAddress'] ?? '',
      shopEmail: data['shopEmail'] ?? '',
      partyName: data['partyName'] ?? '',
      partyAddress: data['partyAddress'] ?? '',
      servedBy: data['servedBy'] ?? '',
      returnedAmount: (data['returnedAmount'] as num?)?.toDouble() ?? 0.0,
      returnStatus: data['returnStatus'] ?? 'NONE',
      paidAmount: paidAmt,
      dueAmount: dueAmt,
      paymentStatus: payStatus,
    );
  }

  factory InvoiceModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return InvoiceModel.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'invoiceId': invoiceId,
      'saleDate': Timestamp.fromDate(saleDate),
      'formattedDate': formattedDate,
      'formattedTime': formattedTime,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'dueAmount': dueAmount,
      'paymentStatus': paymentStatus,
      'totalItems': totalItems,
      'shopName': shopName,
      'shopPhone': shopPhone,
      'shopAddress': shopAddress,
      'shopEmail': shopEmail,
      'partyName': partyName,
      'partyAddress': partyAddress,
      'servedBy': servedBy,
      'qrPayload': qrPayload,
      'returnedAmount': returnedAmount,
      'returnStatus': returnStatus,
      'items': items.map((i) {
        if (i is InvoiceItemModel) {
          return i.toMap();
        }
        return InvoiceItemModel(
          productId: i.productId,
          batchId: i.batchId,
          itemName: i.itemName,
          partNo: i.partNo,
          quantity: i.quantity,
          sellPrice: i.sellPrice,
          costCode: i.costCode,
          returnedQuantity: i.returnedQuantity,
        ).toMap();
      }).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
