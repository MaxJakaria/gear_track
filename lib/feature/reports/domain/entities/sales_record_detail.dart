import 'package:equatable/equatable.dart';

class SalesRecordDetail extends Equatable {
  final String id;
  final DateTime saleDate;
  final String partNo;
  final String itemName;
  final String model;
  final int itemsSold;
  final double sellPrice;
  final String costCode;

  const SalesRecordDetail({
    required this.id,
    required this.saleDate,
    required this.partNo,
    required this.itemName,
    required this.model,
    required this.itemsSold,
    required this.sellPrice,
    required this.costCode,
  });

  @override
  List<Object?> get props => [
        id,
        saleDate,
        partNo,
        itemName,
        model,
        itemsSold,
        sellPrice,
        costCode,
      ];
}
