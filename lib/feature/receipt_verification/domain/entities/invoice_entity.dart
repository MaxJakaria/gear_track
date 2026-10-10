import 'package:equatable/equatable.dart';

class InvoiceItemEntity extends Equatable {
  final String productId;
  final String batchId;
  final String itemName;
  final String partNo;
  final int quantity;
  final double sellPrice;
  final String costCode;
  final int returnedQuantity;

  const InvoiceItemEntity({
    required this.productId,
    this.batchId = '',
    required this.itemName,
    required this.partNo,
    required this.quantity,
    required this.sellPrice,
    this.costCode = '',
    this.returnedQuantity = 0,
  });

  double get subtotal => quantity * sellPrice;
  int get returnableQuantity => (quantity - returnedQuantity).clamp(0, quantity);
  bool get isFullyReturned => returnedQuantity >= quantity;

  @override
  List<Object?> get props => [
    productId,
    batchId,
    itemName,
    partNo,
    quantity,
    sellPrice,
    costCode,
    returnedQuantity,
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
  final String shopEmail;
  final String partyName;
  final String partyAddress;
  final String servedBy;
  final double returnedAmount;
  final String returnStatus; // 'NONE', 'PARTIAL', 'FULL'
  final double paidAmount;
  final double dueAmount;
  final String paymentStatus; // 'PAID', 'PARTIAL', 'DUE'

  const InvoiceEntity({
    required this.invoiceId,
    required this.saleDate,
    required this.totalAmount,
    required this.totalItems,
    required this.items,
    this.shopName = '',
    this.shopPhone = '',
    this.shopAddress = '',
    this.shopEmail = '',
    this.partyName = '',
    this.partyAddress = '',
    this.servedBy = '',
    this.returnedAmount = 0.0,
    this.returnStatus = 'NONE',
    double? paidAmount,
    double? dueAmount,
    String? paymentStatus,
  })  : paidAmount = paidAmount ?? totalAmount,
        dueAmount = dueAmount ?? 0.0,
        paymentStatus = paymentStatus ??
            ((dueAmount != null && dueAmount > 0)
                ? (paidAmount != null && paidAmount > 0 ? 'PARTIAL' : 'DUE')
                : 'PAID');

  bool get hasDue => dueAmount > 0;
  bool get isFullyPaid => dueAmount <= 0;

  bool get hasReturns => returnedAmount > 0 || returnStatus != 'NONE';
  bool get isFullyReturned =>
      returnStatus == 'FULL' ||
      (items.isNotEmpty && items.every((i) => i.isFullyReturned));
  bool get isPartiallyReturned => hasReturns && !isFullyReturned;
  int get remainingReturnableItems =>
      items.fold<int>(0, (sum, i) => sum + i.returnableQuantity);

  String get formattedDate {
    final year = saleDate.year;
    final month = saleDate.month.toString().padLeft(2, '0');
    final day = saleDate.day.toString().padLeft(2, '0');
    return '$day/$month/$year';
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
    shopEmail,
    partyName,
    partyAddress,
    servedBy,
    returnedAmount,
    returnStatus,
    paidAmount,
    dueAmount,
    paymentStatus,
  ];
}
