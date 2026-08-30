part of 'inventory_bloc.dart';

sealed class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object?> get props => [];
}

final class FetchProductsEvent extends InventoryEvent {
  const FetchProductsEvent();
}

final class AddProductEvent extends InventoryEvent {
  final String partNo;
  final String itemName;
  final String model;
  final String costCode;
  final int stockCount;
  final DateTime entryDate;
  final Completer<void>? completer;

  const AddProductEvent({
    required this.partNo,
    required this.itemName,
    required this.model,
    required this.costCode,
    required this.stockCount,
    required this.entryDate,
    this.completer,
  });

  @override
  List<Object?> get props => [
        partNo,
        itemName,
        model,
        costCode,
        stockCount,
        entryDate,
      ];
}

enum StockFilter { all, lowStock, inStock }

final class SearchProductsEvent extends InventoryEvent {
  final String query;
  final StockFilter filter;

  const SearchProductsEvent({
    required this.query,
    this.filter = StockFilter.all,
  });

  @override
  List<Object?> get props => [query, filter];
}

final class UpdateProductEvent extends InventoryEvent {
  final Product product;
  final Completer<void>? completer;

  const UpdateProductEvent(this.product, {this.completer});

  @override
  List<Object?> get props => [product];
}

final class DeleteProductEvent extends InventoryEvent {
  final String productId;
  final Completer<void>? completer;

  const DeleteProductEvent(this.productId, {this.completer});

  @override
  List<Object?> get props => [productId];
}


