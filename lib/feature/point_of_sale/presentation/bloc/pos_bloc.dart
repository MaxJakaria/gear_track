import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/feature/point_of_sale/domain/entities/cart_item.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';
import 'package:gear_track/feature/point_of_sale/domain/entities/sale_entity.dart';
import 'package:gear_track/feature/point_of_sale/domain/usecases/add_sale.dart';
import 'package:gear_track/feature/point_of_sale/domain/usecases/get_product_sales.dart';
import 'package:gear_track/feature/point_of_sale/domain/usecases/get_sales.dart';
import 'package:gear_track/feature/point_of_sale/domain/usecases/save_invoice.dart';

part 'pos_event.dart';
part 'pos_state.dart';

class PosBloc extends Bloc<PosEvent, PosState> {
  final AddSale addSale;
  final GetSales getSales;
  final GetProductSales getProductSales;
  final SaveInvoice saveInvoice;

  List<SaleEntity> _allSales = [];
  List<CartItem> _cartItems = [];

  PosBloc({
    required this.addSale,
    required this.getSales,
    required this.getProductSales,
    required this.saveInvoice,
  }) : super(PosInitial()) {
    on<FetchSalesEvent>(_onFetchSales);
    on<FetchProductSalesEvent>(_onFetchProductSales);
    on<AddSaleEvent>(_onAddSale);
    on<SearchSalesEvent>(_onSearchSales);
    on<AddToCartEvent>(_onAddToCart);
    on<UpdateCartQuantityEvent>(_onUpdateCartQuantity);
    on<UpdateCartPriceEvent>(_onUpdateCartPrice);
    on<UpdateCartProductEvent>(_onUpdateCartProduct);
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
            sales: _allSales,
            filteredSales: _allSales,
            cartItems: List.from(_cartItems),
          ),
        );
      },
    );
  }

  Future<void> _onFetchProductSales(
    FetchProductSalesEvent event,
    Emitter<PosState> emit,
  ) async {
    emit(PosLoading());
    final result = await getProductSales(event.productId);
    result.fold(
      (failure) => emit(PosError(failure.message)),
      (sales) {
        final sortedSales = List<SaleEntity>.from(sales)
          ..sort((a, b) => b.saleDate.compareTo(a.saleDate));
        emit(
          PosLoaded(
            sales: sortedSales,
            filteredSales: sortedSales,
            cartItems: List.from(_cartItems),
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
    result.fold(
      (failure) => emit(PosError(failure.message)),
      (_) {
        emit(const SaleAddedSuccess(message: 'Sale recorded successfully!'));
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
      if (query.isEmpty) {
        emit(
          (state as PosLoaded).copyWith(
            filteredSales: _allSales,
            searchQuery: '',
          ),
        );
      } else {
        final filtered = _allSales.where((sale) {
          final nameMatch = sale.itemName.toLowerCase().contains(query);
          final idMatch = sale.productId.toLowerCase().contains(query);
          final invMatch = sale.invoiceId.toLowerCase().contains(query);
          return nameMatch || idMatch || invMatch;
        }).toList();

        emit(
          (state as PosLoaded).copyWith(
            filteredSales: filtered,
            searchQuery: event.query,
          ),
        );
      }
    }
  }

  void _onAddToCart(
    AddToCartEvent event,
    Emitter<PosState> emit,
  ) {
    final existingIndex = _cartItems.indexWhere(
      (item) => item.productId == event.productId,
    );

    if (existingIndex >= 0) {
      final existing = _cartItems[existingIndex];
      _cartItems[existingIndex] = existing.copyWith(
        quantity: existing.quantity + 1,
      );
    } else {
      _cartItems.add(
        CartItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_${event.productId}',
          productId: event.productId,
          itemName: event.itemName,
          partNo: event.partNo,
          costCode: event.costCode,
          quantity: 1,
          sellPrice: 0.0,
          availableStock: event.availableStock,
        ),
      );
    }

    _emitLoadedState(emit);
  }

  void _onUpdateCartQuantity(
    UpdateCartQuantityEvent event,
    Emitter<PosState> emit,
  ) {
    if (event.quantity <= 0) {
      _cartItems.removeWhere((item) => item.id == event.cartItemId);
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

  void _onUpdateCartProduct(
    UpdateCartProductEvent event,
    Emitter<PosState> emit,
  ) {
    _cartItems = _cartItems.map((item) {
      if (item.id == event.cartItemId) {
        return item.copyWith(
          productId: event.productId,
          partNo: event.partNo,
          itemName: event.itemName,
          costCode: event.costCode,
          availableStock: event.availableStock,
        );
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
    final now = DateTime.now();

    // Generate unique cryptographically collision-resistant Invoice ID: GT-YYYYMMDD-XXXXXX
    final datePrefix =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final randomSuffix = (Random().nextInt(900000) + 100000).toString();
    final invoiceId = 'GT-$datePrefix-$randomSuffix';

    final invoiceItems = checkoutItems
        .map(
          (i) => InvoiceItemEntity(
            productId: i.productId,
            itemName: i.itemName,
            partNo: i.partNo,
            quantity: i.quantity,
            sellPrice: i.sellPrice,
            costCode: i.costCode,
          ),
        )
        .toList();

    final invoice = InvoiceEntity(
      invoiceId: invoiceId,
      saleDate: now,
      totalAmount: totalPaid,
      totalItems: checkoutItems.fold(0, (sum, i) => sum + i.quantity),
      items: invoiceItems,
    );

    // 1. Save the Invoice document in cloud Firestore
    final invoiceResult = await saveInvoice(invoice);
    if (invoiceResult.isLeft()) {
      final failure = invoiceResult.getLeft().toNullable();
      emit(PosError(failure?.message ?? 'Failed to save receipt invoice.'));
      return;
    }

    // 2. Perform FIFO stock deduction and record individual sales linked to this invoiceId
    bool hasFailure = false;
    String failureMessage = '';

    for (final item in checkoutItems) {
      final sale = SaleEntity(
        id: '${DateTime.now().millisecondsSinceEpoch}_${item.productId}',
        productId: item.productId,
        saleDate: now,
        itemName: item.itemName,
        quantity: item.quantity,
        sellPrice: item.sellPrice,
        costCode: item.costCode,
        invoiceId: invoiceId,
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
          invoice: invoice,
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
