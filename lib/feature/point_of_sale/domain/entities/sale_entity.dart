import 'package:equatable/equatable.dart';

class SaleEntity extends Equatable {
  final String id;
  final String productId;
  final String batchId;
  final String partNo;
  final DateTime saleDate;
  final String itemName;
  final int quantity;
  final double sellPrice;
  final String costCode;
  final String invoiceId;
  final String partyName;
  final String partyAddress;
  final String servedBy;

  const SaleEntity({
    required this.id,
    required this.productId,
    this.batchId = '',
    this.partNo = '',
    required this.saleDate,
    required this.itemName,
    required this.quantity,
    required this.sellPrice,
    required this.costCode,
    this.invoiceId = '',
    this.partyName = '',
    this.partyAddress = '',
    this.servedBy = '',
  });

  @override
  List<Object?> get props => [
    id,
    productId,
    batchId,
    partNo,
    saleDate,
    itemName,
    quantity,
    sellPrice,
    costCode,
    invoiceId,
    partyName,
    partyAddress,
    servedBy,
  ];
}
