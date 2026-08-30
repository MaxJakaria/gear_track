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

  List<GroupedProduct> get filteredGroupedProducts => _group(filteredProducts);

  int get totalSkus => groupedProducts.length;

  int get totalStockUnits => products.fold(0, (sum, item) => sum + item.stockCount);

  int get lowStockCount => groupedProducts.where((item) => item.totalStockCount <= 5).length;

  static List<GroupedProduct> _group(List<Product> list) {
    final Map<String, List<Product>> map = {};
    for (final p in list) {
      final key = p.itemName.trim().toLowerCase();
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


