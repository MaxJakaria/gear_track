import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gear_track/feature/inventory/domain/entities/grouped_product.dart';
import 'package:gear_track/feature/inventory/domain/entities/product.dart';
import 'package:gear_track/feature/inventory/domain/usecases/add_product.dart';
import 'package:gear_track/feature/inventory/domain/usecases/delete_product.dart';
import 'package:gear_track/feature/inventory/domain/usecases/get_product.dart';
import 'package:gear_track/feature/inventory/domain/usecases/update_product.dart';


part 'inventory_event.dart';
part 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final AddProduct addProduct;
  final GetProducts getProducts;
  final UpdateProduct updateProduct;
  final DeleteProduct deleteProduct;

  List<Product> _allProducts = [];

  InventoryBloc({
    required this.addProduct,
    required this.getProducts,
    required this.updateProduct,
    required this.deleteProduct,
  }) : super(InventoryInitial()) {
    on<FetchProductsEvent>(_onFetchProducts);
    on<AddProductEvent>(_onAddProduct);
    on<SearchProductsEvent>(_onSearchProducts);
    on<UpdateProductEvent>(_onUpdateProduct);
    on<DeleteProductEvent>(_onDeleteProduct);
  }

  Future<void> _onFetchProducts(
    FetchProductsEvent event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    final result = await getProducts();
    result.fold(
      (failure) => emit(InventoryError(failure.message)),
      (products) {
        _allProducts = products;
        emit(
          InventoryLoaded(
            products: products,
            filteredProducts: products,
          ),
        );
      },
    );
  }

  Future<void> _onAddProduct(
    AddProductEvent event,
    Emitter<InventoryState> emit,
  ) async {
    emit(ProductAdding());

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newProduct = Product(
      id: id,
      entryDate: event.entryDate,
      partNo: event.partNo,
      itemName: event.itemName,
      model: event.model,
      costCode: event.costCode,
      stockCount: event.stockCount,
    );

    final result = await addProduct(newProduct);
    await result.fold(
      (failure) async {
        emit(InventoryError(failure.message));
      },
      (_) async {
        emit(const ProductAddedSuccess());
        // Reload products after successful addition
        add(const FetchProductsEvent());
      },
    );
  }

  Future<void> _onUpdateProduct(
    UpdateProductEvent event,
    Emitter<InventoryState> emit,
  ) async {
    emit(ProductUpdating());
    final result = await updateProduct(event.product);
    await result.fold(
      (failure) async {
        emit(InventoryError(failure.message));
      },
      (_) async {
        emit(const ProductUpdatedSuccess());
        // Reload products after successful update
        add(const FetchProductsEvent());
      },
    );
  }

  Future<void> _onDeleteProduct(
    DeleteProductEvent event,
    Emitter<InventoryState> emit,
  ) async {
    emit(ProductDeleting());
    final result = await deleteProduct(event.productId);
    await result.fold(
      (failure) async {
        emit(InventoryError(failure.message));
      },
      (_) async {
        emit(const ProductDeletedSuccess());
        // Reload products after successful deletion
        add(const FetchProductsEvent());
      },
    );
  }

  void _onSearchProducts(
    SearchProductsEvent event,
    Emitter<InventoryState> emit,
  ) {
    if (state is InventoryLoaded) {
      final query = event.query.toLowerCase().trim();
      final filter = event.filter;

      final filtered = _allProducts.where((product) {
        final matchesQuery = query.isEmpty ||
            product.itemName.toLowerCase().contains(query) ||
            product.partNo.toLowerCase().contains(query) ||
            product.model.toLowerCase().contains(query);

        final matchesFilter = switch (filter) {
          StockFilter.all => true,
          StockFilter.lowStock => product.stockCount <= 5,
          StockFilter.inStock => product.stockCount > 5,
        };

        return matchesQuery && matchesFilter;
      }).toList();

      emit(
        InventoryLoaded(
          products: _allProducts,
          filteredProducts: filtered,
          searchQuery: event.query,
          activeFilter: filter,
        ),
      );
    }
  }
}


