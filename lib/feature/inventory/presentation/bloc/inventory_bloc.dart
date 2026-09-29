import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gear_track/feature/inventory/domain/entities/grouped_product.dart';
import 'package:gear_track/feature/inventory/domain/entities/product.dart';
import 'package:gear_track/feature/inventory/domain/usecases/add_product.dart';
import 'package:gear_track/feature/inventory/domain/usecases/clear_all_products.dart';
import 'package:gear_track/feature/inventory/domain/usecases/delete_product.dart';
import 'package:gear_track/feature/inventory/domain/usecases/get_product.dart';
import 'package:gear_track/feature/inventory/domain/usecases/update_grouped_product_details.dart';
import 'package:gear_track/feature/inventory/domain/usecases/update_product.dart';

part 'inventory_event.dart';
part 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final AddProduct addProduct;
  final GetProducts getProducts;
  final UpdateProduct updateProduct;
  final UpdateGroupedProductDetails updateGroupedProductDetails;
  final DeleteProduct deleteProduct;
  final ClearAllProducts clearAllProducts;

  List<Product> _allProducts = [];

  InventoryBloc({
    required this.addProduct,
    required this.getProducts,
    required this.updateProduct,
    required this.updateGroupedProductDetails,
    required this.deleteProduct,
    required this.clearAllProducts,
  }) : super(InventoryInitial()) {
    on<FetchProductsEvent>(_onFetchProducts);
    on<AddProductEvent>(_onAddProduct);
    on<SearchProductsEvent>(_onSearchProducts);
    on<UpdateProductEvent>(_onUpdateProduct);
    on<UpdateGroupedProductDetailsEvent>(_onUpdateGroupedProductDetails);
    on<DeleteProductEvent>(_onDeleteProduct);
    on<ClearAllProductsEvent>(_onClearAllProducts);
    on<ClearOutOfStockBatchesEvent>(_onClearOutOfStockBatches);
  }

  List<Product> _filterProducts(
    List<Product> list,
    String query,
    StockFilter filter,
  ) {
    final q = query.toLowerCase().trim();
    return list.where((product) {
      final matchesQuery =
          q.isEmpty ||
          product.itemName.toLowerCase().contains(q) ||
          product.partNo.toLowerCase().contains(q) ||
          product.model.toLowerCase().contains(q);

      final matchesFilter = switch (filter) {
        StockFilter.all => true,
        StockFilter.inStock => product.stockCount > 0,
        StockFilter.lowStockProduct || StockFilter.lowStockBatch =>
          product.stockCount > 0 && product.stockCount <= 5,
        StockFilter.outOfStockProduct || StockFilter.outOfStockBatch =>
          product.stockCount <= 0,
      };

      return matchesQuery && matchesFilter;
    }).toList();
  }

  Future<void> _fetchAndEmit(Emitter<InventoryState> emit) async {
    final result = await getProducts();
    result.fold(
      (failure) {
        if (_allProducts.isEmpty) {
          emit(InventoryError(failure.message));
        }
      },
      (products) {
        _allProducts = products;
        final currentQuery = (state is InventoryLoaded)
            ? (state as InventoryLoaded).searchQuery
            : '';
        final currentFilter = (state is InventoryLoaded)
            ? (state as InventoryLoaded).activeFilter
            : StockFilter.all;

        final filtered = _filterProducts(products, currentQuery, currentFilter);
        emit(
          InventoryLoaded(
            products: products,
            filteredProducts: filtered,
            searchQuery: currentQuery,
            activeFilter: currentFilter,
          ),
        );
      },
    );
  }

  Future<void> _onFetchProducts(
    FetchProductsEvent event,
    Emitter<InventoryState> emit,
  ) async {
    if (_allProducts.isEmpty) {
      emit(InventoryLoading());
    }
    await _fetchAndEmit(emit);
  }

  Future<void> _onAddProduct(
    AddProductEvent event,
    Emitter<InventoryState> emit,
  ) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newProduct = Product(
      id: id,
      entryDate: event.entryDate,
      partNo: event.partNo,
      itemName: event.itemName,
      model: event.model,
      costCode: event.costCode,
      initialQuantity: event.stockCount,
      stockCount: event.stockCount,
    );

    final result = await addProduct(newProduct);
    await result.fold(
      (failure) async {
        emit(InventoryError(failure.message));
        event.completer?.completeError(failure.message);
      },
      (_) async {
        await _fetchAndEmit(emit);
        event.completer?.complete();
      },
    );
  }

  Future<void> _onUpdateProduct(
    UpdateProductEvent event,
    Emitter<InventoryState> emit,
  ) async {
    final result = await updateProduct(event.product);
    await result.fold(
      (failure) async {
        emit(InventoryError(failure.message));
        event.completer?.completeError(failure.message);
      },
      (_) async {
        await _fetchAndEmit(emit);
        event.completer?.complete();
      },
    );
  }

  Future<void> _onUpdateGroupedProductDetails(
    UpdateGroupedProductDetailsEvent event,
    Emitter<InventoryState> emit,
  ) async {
    final result = await updateGroupedProductDetails(
      groupedProduct: event.groupedProduct,
      newItemName: event.newItemName,
      newModel: event.newModel,
    );
    await result.fold(
      (failure) async {
        emit(InventoryError(failure.message));
        event.completer?.completeError(failure.message);
      },
      (_) async {
        await _fetchAndEmit(emit);
        event.completer?.complete();
      },
    );
  }

  Future<void> _onDeleteProduct(
    DeleteProductEvent event,
    Emitter<InventoryState> emit,
  ) async {
    final result = await deleteProduct(event.productId);
    await result.fold(
      (failure) async {
        emit(InventoryError(failure.message));
        event.completer?.completeError(failure.message);
      },
      (_) async {
        await _fetchAndEmit(emit);
        event.completer?.complete();
      },
    );
  }

  Future<void> _onClearAllProducts(
    ClearAllProductsEvent event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    final result = await clearAllProducts();
    await result.fold(
      (failure) async {
        emit(InventoryError(failure.message));
        event.completer?.completeError(failure.message);
      },
      (_) async {
        _allProducts = [];
        emit(
          const InventoryLoaded(
            products: [],
            filteredProducts: [],
            searchQuery: '',
            activeFilter: StockFilter.all,
          ),
        );
        event.completer?.complete();
      },
    );
  }

  Future<void> _onClearOutOfStockBatches(
    ClearOutOfStockBatchesEvent event,
    Emitter<InventoryState> emit,
  ) async {
    final outOfStockBatches =
        _allProducts.where((p) => p.stockCount <= 0).toList();
    if (outOfStockBatches.isEmpty) {
      event.completer?.complete();
      return;
    }

    emit(InventoryLoading());
    try {
      for (final batch in outOfStockBatches) {
        await deleteProduct(batch.id);
      }
      await _fetchAndEmit(emit);
      event.completer?.complete();
    } catch (e) {
      emit(InventoryError(e.toString()));
      event.completer?.completeError(e);
    }
  }

  void _onSearchProducts(
    SearchProductsEvent event,
    Emitter<InventoryState> emit,
  ) {
    if (state is InventoryLoaded) {
      final filtered = _filterProducts(_allProducts, event.query, event.filter);

      emit(
        InventoryLoaded(
          products: _allProducts,
          filteredProducts: filtered,
          searchQuery: event.query,
          activeFilter: event.filter,
        ),
      );
    }
  }
}
