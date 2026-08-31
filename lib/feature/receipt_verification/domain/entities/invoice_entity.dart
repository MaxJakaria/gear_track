import 'package:equatable/equatable.dart';

class InvoiceItemEntity extends Equatable {
  final String productId;
  final String itemName;
  final String partNo;
  final int quantity;
  final double sellPrice;
  final String costCode;

  const InvoiceItemEntity({
    required this.productId,
    required this.itemName,
    required this.partNo,
    required this.quantity,
    required this.sellPrice,
    this.costCode = '',
  });

  double get subtotal => quantity * sellPrice;

  @override
  List<Object?> get props => [
    productId,
    itemName,
    partNo,
    quantity,
    sellPrice,
    costCode,
  ];
}

class InvoiceEntity extends Equatable {
  final String invoiceId;
  final DateTime saleDate;
  final double totalAmount;
  final int totalItems;
  final List<InvoiceItemEntity> items;
  final String shopName;
  final String shopPhone;
  final String shopAddress;

  const InvoiceEntity({
    required this.invoiceId,
    required this.saleDate,
    required this.totalAmount,
    required this.totalItems,
    required this.items,
    this.shopName = '',
    this.shopPhone = '',
    this.shopAddress = '',
  });

  String get formattedDate {
    final year = saleDate.year;
    final month = saleDate.month.toString().padLeft(2, '0');
    final day = saleDate.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String get formattedTime {
    final hour = saleDate.hour.toString().padLeft(2, '0');
    final minute = saleDate.minute.toString().padLeft(2, '0');
    final second = saleDate.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  /// Encoded QR/Barcode payload containing Unique ID, Date, Time and Total
  String get qrPayload =>
      'GT-RECEIPT|ID:$invoiceId|DATE:$formattedDate|TIME:$formattedTime|TOTAL:${totalAmount.toStringAsFixed(2)}';

  @override
  List<Object?> get props => [
    invoiceId,
    saleDate,
    totalAmount,
    totalItems,
    items,
    shopName,
    shopPhone,
    shopAddress,
  ];
}
