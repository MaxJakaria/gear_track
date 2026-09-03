import 'package:equatable/equatable.dart';

/// Live collection metrics entity for Database Maintenance
class DatabaseMetrics extends Equatable {
  final int productsCount;
  final int batchesCount;
  final int invoicesCount;
  final int salesCount;
  final int returnsCount;

  const DatabaseMetrics({
    this.productsCount = 0,
    this.batchesCount = 0,
    this.invoicesCount = 0,
    this.salesCount = 0,
    this.returnsCount = 0,
  });

  bool get isEmpty =>
      productsCount == 0 &&
      batchesCount == 0 &&
      invoicesCount == 0 &&
      salesCount == 0 &&
      returnsCount == 0;

  @override
  List<Object?> get props => [
        productsCount,
        batchesCount,
        invoicesCount,
        salesCount,
        returnsCount,
      ];
}
