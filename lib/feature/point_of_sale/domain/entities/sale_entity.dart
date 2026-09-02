import 'package:equatable/equatable.dart';

class SaleEntity extends Equatable {
  final String id;
  final String productId;
  final String partNo;
  final DateTime saleDate;
  final String itemName;
  final int quantity;
  final double sellPrice;
  final String costCode;
  final String invoiceId;

  const SaleEntity({
    required this.id,
    required this.productId,
    this.partNo = '',
    required this.saleDate,
    required this.itemName,
    required this.quantity,
    required this.sellPrice,
    required this.costCode,
    this.invoiceId = '',
  });

  @override
  List<Object?> get props => [
    id,
    productId,
    partNo,
    saleDate,
    itemName,
    quantity,
    sellPrice,
    costCode,
    invoiceId,
  ];
}
