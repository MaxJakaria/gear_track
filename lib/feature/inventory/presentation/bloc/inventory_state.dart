part of 'inventory_bloc.dart';

sealed class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

final class InventoryInitial extends InventoryState {}

final class InventoryLoading extends InventoryState {}

final class InventoryLoaded extends InventoryState {
  final List<Product> products;
  final List<Product> filteredProducts;
  final String searchQuery;
  final StockFilter activeFilter;

  const InventoryLoaded({
    required this.products,
    required this.filteredProducts,
    this.searchQuery = '',
    this.activeFilter = StockFilter.all,
  });

  List<GroupedProduct> get groupedProducts => _group(products);

  List<GroupedProduct> get filteredGroupedProducts {
    final q = searchQuery.toLowerCase().trim();
    return groupedProducts.where((grouped) {
      final matchesQuery = q.isEmpty ||
          grouped.itemName.toLowerCase().contains(q) ||
          grouped.partNo.toLowerCase().contains(q) ||
          grouped.model.toLowerCase().contains(q) ||
          grouped.batches.any((b) => b.partNo.toLowerCase().contains(q));

      final matchesFilter = switch (activeFilter) {
        StockFilter.all => true,
        StockFilter.inStock => grouped.totalStockCount > 0,
        StockFilter.lowStockProduct =>
          grouped.totalStockCount > 0 && grouped.totalStockCount <= 5,
        StockFilter.lowStockBatch => grouped.hasLowStockBatch,
        StockFilter.outOfStockProduct => grouped.totalStockCount <= 0,
        StockFilter.outOfStockBatch => grouped.hasOutOfStockBatch,
      };

      return matchesQuery && matchesFilter;
    }).toList();
  }

  List<Product> get filteredBatches {
    final q = searchQuery.toLowerCase().trim();
    return products.where((batch) {
      final matchesQuery = q.isEmpty ||
          batch.itemName.toLowerCase().contains(q) ||
          batch.partNo.toLowerCase().contains(q) ||
          batch.model.toLowerCase().contains(q);

      final matchesFilter = switch (activeFilter) {
        StockFilter.lowStockBatch =>
          batch.stockCount > 0 && batch.stockCount <= 5,
        StockFilter.outOfStockBatch => batch.stockCount <= 0,
        _ => true,
      };

      return matchesQuery && matchesFilter;
    }).toList();
  }

  List<GroupedProduct> get filteredBatchesGrouped {
    final batches = filteredBatches;
    final Map<String, List<Product>> map = {};
    for (final p in batches) {
      final nameKey = p.itemName.trim().toLowerCase();
      final modelKey = p.model.trim().toLowerCase();
      final key = '$nameKey###$modelKey';
      map.putIfAbsent(key, () => []).add(p);
    }
    return map.entries
        .map((entry) =>
            GroupedProduct.fromBatches(entry.value.first.partNo, entry.value))
        .toList();
  }

  int get totalSkus => groupedProducts.length;

  int get totalStockUnits =>
      products.fold(0, (sum, item) => sum + item.stockCount);

  int get inStockCount =>
      groupedProducts.where((item) => item.totalStockCount > 0).length;

  int get lowStockProductCount => groupedProducts
      .where((item) => item.totalStockCount > 0 && item.totalStockCount <= 5)
      .length;

  int get lowStockBatchCount =>
      products.where((item) => item.stockCount > 0 && item.stockCount <= 5).length;

  int get outOfStockProductCount =>
      groupedProducts.where((item) => item.totalStockCount <= 0).length;

  int get outOfStockBatchCount =>
      products.where((item) => item.stockCount <= 0).length;

  int get lowStockCount => lowStockProductCount;

  int get outOfStockCount => outOfStockProductCount;

  static List<GroupedProduct> _group(List<Product> list) {
    final Map<String, List<Product>> map = {};
    for (final p in list) {
      final nameKey = p.itemName.trim().toLowerCase();
      final modelKey = p.model.trim().toLowerCase();
      final key = '$nameKey###$modelKey';
      map.putIfAbsent(key, () => []).add(p);
    }
    return map.entries
        .map((e) => GroupedProduct.fromBatches(e.value.first.partNo, e.value))
        .toList();
  }

  InventoryLoaded copyWith({
    List<Product>? products,
    List<Product>? filteredProducts,
    String? searchQuery,
    StockFilter? activeFilter,
  }) {
    return InventoryLoaded(
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }

  @override
  List<Object?> get props => [products, filteredProducts, searchQuery, activeFilter];
}


final class ProductAdding extends InventoryState {}

final class ProductAddedSuccess extends InventoryState {
  final String message;
  const ProductAddedSuccess({this.message = 'Product added successfully!'});

  @override
  List<Object?> get props => [message];
}

final class ProductUpdating extends InventoryState {}

final class ProductUpdatedSuccess extends InventoryState {
  final String message;
  const ProductUpdatedSuccess({this.message = 'Product updated successfully!'});

  @override
  List<Object?> get props => [message];
}

final class ProductDeleting extends InventoryState {}

final class ProductDeletedSuccess extends InventoryState {
  final String message;
  const ProductDeletedSuccess({this.message = 'Product deleted successfully!'});

  @override
  List<Object?> get props => [message];
}

final class InventoryError extends InventoryState {
  final String message;
  const InventoryError(this.message);

  @override
  List<Object?> get props => [message];
}


