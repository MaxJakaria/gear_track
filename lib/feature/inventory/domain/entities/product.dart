import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final DateTime entryDate;
  final String partNo;
  final String itemName;
  final String model;
  final String costCode;
  final int stockCount;

  const Product({
    required this.id,
    required this.entryDate,
    required this.partNo,
    required this.itemName,
    required this.model,
    required this.costCode,
    required this.stockCount,
  });

  @override
  List<Object?> get props => [
    id,
    entryDate,
    partNo,
    itemName,
    model,
    costCode,
    stockCount,
  ];
}
