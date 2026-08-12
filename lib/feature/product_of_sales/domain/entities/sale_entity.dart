import 'package:equatable/equatable.dart';

class SaleEntity extends Equatable {
  final String id;
  final DateTime saleDate;
  final String itemName;
  final int quantity;
  final double sellPrice;
  final String costCode;

  const SaleEntity({
    required this.id,
    required this.saleDate,
    required this.itemName,
    required this.quantity,
    required this.sellPrice,
    required this.costCode,
  });

  @override
  List<Object?> get props => [
    id,
    saleDate,
    itemName,
    quantity,
    sellPrice,
    costCode,
  ];
}
