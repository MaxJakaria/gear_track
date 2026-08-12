import 'package:equatable/equatable.dart';
import 'package:gear_track/feature/inventory/domain/entities/product.dart';

class GroupedProduct extends Equatable {
  final String partNo;
  final String itemName;
  final String model;
  final int totalStockCount;
  final int batchCount;
  final String latestCostCode;
  final DateTime latestEntryDate;
  final List<Product> batches;

  const GroupedProduct({
    required this.partNo,
    required this.itemName,
    required this.model,
    required this.totalStockCount,
    required this.batchCount,
    required this.latestCostCode,
    required this.latestEntryDate,
    required this.batches,
  });

  factory GroupedProduct.fromBatches(String partNo, List<Product> rawBatches) {
    final sorted = List<Product>.from(rawBatches)
      ..sort((a, b) => b.entryDate.compareTo(a.entryDate));

    final first = sorted.first;
    final totalStock = sorted.fold(0, (sum, item) => sum + item.stockCount);

    return GroupedProduct(
      partNo: partNo,
      itemName: first.itemName,
      model: first.model,
      totalStockCount: totalStock,
      batchCount: sorted.length,
      latestCostCode: first.costCode,
      latestEntryDate: first.entryDate,
      batches: sorted,
    );
  }

  @override
  List<Object?> get props => [
        partNo,
        itemName,
        model,
        totalStockCount,
        batchCount,
        latestCostCode,
        latestEntryDate,
        batches,
      ];
}
