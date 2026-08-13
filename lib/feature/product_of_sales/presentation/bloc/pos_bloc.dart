import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/feature/product_of_sales/domain/entities/cart_item.dart';
import 'package:gear_track/feature/product_of_sales/domain/entities/sale_entity.dart';
import 'package:gear_track/feature/product_of_sales/domain/usecases/add_sale.dart';
import 'package:gear_track/feature/product_of_sales/domain/usecases/get_sales.dart';

part 'pos_event.dart';
part 'pos_state.dart';

class PosBloc extends Bloc<PosEvent, PosState> {
  final AddSale addSale;
  final GetSales getSales;

  List<SaleEntity> _allSales = [];
  List<CartItem> _cartItems = [];

  PosBloc({
    required this.addSale,
    required this.getSales,
  }) : super(PosInitial()) {
    on<FetchSalesEvent>(_onFetchSales);
    on<AddSaleEvent>(_onAddSale);
    on<SearchSalesEvent>(_onSearchSales);
    on<AddToCartEvent>(_onAddToCart);
    on<UpdateCartQuantityEvent>(_onUpdateCartQuantity);
    on<UpdateCartPriceEvent>(_onUpdateCartPrice);
    on<RemoveCartItemEvent>(_onRemoveCartItem);
    on<ClearCartEvent>(_onClearCart);
    on<CheckoutCartEvent>(_onCheckoutCart);
  }

  Future<void> _onFetchSales(
    FetchSalesEvent event,
    Emitter<PosState> emit,
  ) async {
    emit(PosLoading());
    final result = await getSales();
    result.fold(
      (failure) => emit(PosError(failure.message)),
      (sales) {
        final sortedSales = List<SaleEntity>.from(sales)
          ..sort((a, b) => b.saleDate.compareTo(a.saleDate));
        _allSales = sortedSales;
        emit(
          PosLoaded(
            sales: sortedSales,
            filteredSales: sortedSales,
            cartItems: _cartItems,
          ),
        );
      },
    );
  }

  Future<void> _onAddSale(
    AddSaleEvent event,
    Emitter<PosState> emit,
  ) async {
    emit(SaleAdding());
    final result = await addSale(event.sale);
    await result.fold(
      (failure) async {
        emit(PosError(failure.message));
      },
      (_) async {
        emit(const SaleAddedSuccess());
        add(const FetchSalesEvent());
      },
    );
  }

  void _onSearchSales(
    SearchSalesEvent event,
    Emitter<PosState> emit,
  ) {
    if (state is PosLoaded) {
      final query = event.query.toLowerCase().trim();

      final filtered = _allSales.where((sale) {
        return query.isEmpty ||
            sale.itemName.toLowerCase().contains(query) ||
            sale.costCode.toLowerCase().contains(query);
      }).toList();

      emit(
        (state as PosLoaded).copyWith(
          filteredSales: filtered,
          searchQuery: event.query,
        ),
      );
    }
  }

  void _onAddToCart(
    AddToCartEvent event,
    Emitter<PosState> emit,
  ) {
    final existingIndex =
        _cartItems.indexWhere((item) => item.productId == event.productId);

    if (existingIndex >= 0) {
      final existing = _cartItems[existingIndex];
      _cartItems[existingIndex] = existing.copyWith(
        quantity: existing.quantity + 1,
      );
    } else {
      final newItem = CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: event.productId,
        itemName: event.itemName,
        partNo: event.partNo,
        costCode: event.costCode,
        availableStock: event.availableStock,
        quantity: 1,
        sellPrice: 0.0,
      );
      _cartItems = [..._cartItems, newItem];
    }

    _emitLoadedState(emit);
  }

  void _onUpdateCartQuantity(
    UpdateCartQuantityEvent event,
    Emitter<PosState> emit,
  ) {
    if (event.quantity <= 0) {
      _cartItems = _cartItems.where((i) => i.id != event.cartItemId).toList();
    } else {
      _cartItems = _cartItems.map((item) {
        if (item.id == event.cartItemId) {
          return item.copyWith(quantity: event.quantity);
        }
        return item;
      }).toList();
    }
    _emitLoadedState(emit);
  }

  void _onUpdateCartPrice(
    UpdateCartPriceEvent event,
    Emitter<PosState> emit,
  ) {
    _cartItems = _cartItems.map((item) {
      if (item.id == event.cartItemId) {
        return item.copyWith(sellPrice: event.price);
      }
      return item;
    }).toList();
    _emitLoadedState(emit);
  }

  void _onRemoveCartItem(
    RemoveCartItemEvent event,
    Emitter<PosState> emit,
  ) {
    _cartItems = _cartItems.where((i) => i.id != event.cartItemId).toList();
    _emitLoadedState(emit);
  }

  void _onClearCart(
    ClearCartEvent event,
    Emitter<PosState> emit,
  ) {
    _cartItems = [];
    _emitLoadedState(emit);
  }

  Future<void> _onCheckoutCart(
    CheckoutCartEvent event,
    Emitter<PosState> emit,
  ) async {
    if (_cartItems.isEmpty) return;

    emit(SaleAdding());

    final checkoutItems = List<CartItem>.from(_cartItems);
    final totalPaid = checkoutItems.fold(0.0, (sum, i) => sum + i.subtotal);

    bool hasFailure = false;
    String failureMessage = '';

    for (final item in checkoutItems) {
      final sale = SaleEntity(
        id: '${DateTime.now().millisecondsSinceEpoch}_${item.productId}',
        productId: item.productId,
        saleDate: DateTime.now(),
        itemName: item.itemName,
        quantity: item.quantity,
        sellPrice: item.sellPrice,
        costCode: item.costCode,
      );

      final result = await addSale(sale);
      result.fold(
        (failure) {
          hasFailure = true;
          failureMessage = failure.message;
        },
        (_) {},
      );
    }

    if (hasFailure) {
      emit(PosError(failureMessage));
    } else {
      _cartItems = [];
      emit(
        SaleAddedSuccess(
          checkoutCartItems: checkoutItems,
          totalPaid: totalPaid,
          message: 'Bill generated & sales saved successfully!',
        ),
      );
      add(const FetchSalesEvent());
    }
  }

  void _emitLoadedState(Emitter<PosState> emit) {
    if (state is PosLoaded) {
      emit((state as PosLoaded).copyWith(cartItems: List.from(_cartItems)));
    } else {
      emit(
        PosLoaded(
          sales: _allSales,
          filteredSales: _allSales,
          cartItems: List.from(_cartItems),
        ),
      );
    }
  }
}
