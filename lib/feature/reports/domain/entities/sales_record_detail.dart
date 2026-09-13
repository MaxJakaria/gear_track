import 'package:equatable/equatable.dart';

class SalesRecordDetail extends Equatable {
  final String id;
  final String invoiceId;
  final DateTime saleDate;
  final String partNo;
  final String itemName;
  final String model;
  final int itemsSold;
  final double sellPrice;
  final String costCode;
  final String partyName;
  final String partyAddress;
  final String servedBy;

  const SalesRecordDetail({
    required this.id,
    this.invoiceId = '',
    required this.saleDate,
    required this.partNo,
    required this.itemName,
    required this.model,
    required this.itemsSold,
    required this.sellPrice,
    required this.costCode,
    this.partyName = '',
    this.partyAddress = '',
    this.servedBy = '',
  });

  @override
  List<Object?> get props => [
    id,
    invoiceId,
    saleDate,
    partNo,
    itemName,
    model,
    itemsSold,
    sellPrice,
    costCode,
    partyName,
    partyAddress,
    servedBy,
  ];
}
