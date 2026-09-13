import 'package:equatable/equatable.dart';

class ReturnItemEntity extends Equatable {
  final String productId;
  final String batchId;
  final String itemName;
  final String partNo;
  final int quantity;
  final double sellPrice;
  final String costCode;
  final bool restock;
  final String reason;

  const ReturnItemEntity({
    required this.productId,
    this.batchId = '',
    required this.itemName,
    required this.partNo,
    required this.quantity,
    required this.sellPrice,
    this.costCode = '',
    this.restock = true,
    this.reason = 'Customer Return',
  });

  double get refundAmount => quantity * sellPrice;

  @override
  List<Object?> get props => [
    productId,
    batchId,
    itemName,
    partNo,
    quantity,
    sellPrice,
    costCode,
    restock,
    reason,
  ];
}

class ReturnEntity extends Equatable {
  final String returnId;
  final String invoiceId;
  final DateTime returnDate;
  final double totalRefundAmount;
  final int totalQuantity;
  final String reason;
  final List<ReturnItemEntity> items;
  final String shopName;

  const ReturnEntity({
    required this.returnId,
    required this.invoiceId,
    required this.returnDate,
    required this.totalRefundAmount,
    required this.totalQuantity,
    required this.reason,
    required this.items,
    this.shopName = '',
  });

  String get formattedDate {
    final year = returnDate.year;
    final month = returnDate.month.toString().padLeft(2, '0');
    final day = returnDate.day.toString().padLeft(2, '0');
    return '$day/$month/$year';
  }

  String get formattedTime {
    final hour = returnDate.hour.toString().padLeft(2, '0');
    final minute = returnDate.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  List<Object?> get props => [
    returnId,
    invoiceId,
    returnDate,
    totalRefundAmount,
    totalQuantity,
    reason,
    items,
    shopName,
  ];
}
