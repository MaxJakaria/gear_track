import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/feature/point_of_sale/domain/entities/cart_item.dart';
import 'package:gear_track/feature/point_of_sale/domain/entities/sale_entity.dart';
import 'package:gear_track/feature/point_of_sale/domain/usecases/add_sale.dart';
import 'package:gear_track/feature/point_of_sale/domain/usecases/checkout_cart.dart';
import 'package:gear_track/feature/point_of_sale/domain/usecases/get_product_sales.dart';
import 'package:gear_track/feature/point_of_sale/domain/usecases/get_sales.dart';
import 'package:gear_track/feature/point_of_sale/domain/usecases/save_invoice.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';

part 'pos_event.dart';
part 'pos_state.dart';

class PosBloc extends Bloc<PosEvent, PosState> {
  final GetSales getSales;
  final AddSale addSale;
  final CheckoutCart checkoutCart;
  final GetProductSales getProductSales;
  final SaveInvoice saveInvoice;

  List<CartItem> _cartItems = [];
  List<SaleEntity> _allSales = [];

  PosBloc({
    required this.getSales,
    required this.addSale,
    required this.checkoutCart,
    required this.getProductSales,
    required this.saveInvoice,
  }) : super(PosInitial()) {
    on<LoadSalesEvent>(_onLoadSales);
    on<FetchSalesEvent>(_onFetchSales);
    on<SearchSalesEvent>(_onSearchSales);
    on<AddToCartEvent>(_onAddToCart);
    on<UpdateCartQuantityEvent>(_onUpdateCartQuantity);
    on<UpdateCartPriceEvent>(_onUpdateCartPrice);
    on<UpdateCartCostCodeEvent>(_onUpdateCartCostCode);
    on<UpdateCartProductEvent>(_onUpdateCartProduct);
    on<RemoveCartItemEvent>(_onRemoveCartItem);
    on<ClearCartEvent>(_onClearCart);
    on<CheckoutCartEvent>(_onCheckoutCart);
  }

  void _emitLoadedState(
    Emitter<PosState> emit, {
    String searchQuery = '',
    List<SaleEntity>? searchResults,
  }) {
    emit(
      PosLoaded(
        sales: _allSales,
        filteredSales: searchResults ?? _allSales,
        cartItems: List.unmodifiable(_cartItems),
        searchQuery: searchQuery,
      ),
    );
  }

  Future<void> _onLoadSales(
    LoadSalesEvent event,
    Emitter<PosState> emit,
  ) async {
    emit(PosLoading());
    final salesResult = await getSales();

    salesResult.fold(
      (failure) => emit(PosError(failure.message)),
      (sales) {
        _allSales = sales;
        _emitLoadedState(emit);
      },
    );
  }

  Future<void> _onFetchSales(
    FetchSalesEvent event,
    Emitter<PosState> emit,
  ) async {
    emit(PosLoading());
    final salesResult = await getSales();

    salesResult.fold(
      (failure) => emit(PosError(failure.message)),
      (sales) {
        _allSales = sales;
        _emitLoadedState(emit);
      },
    );
  }

  void _onSearchSales(
    SearchSalesEvent event,
    Emitter<PosState> emit,
  ) {
    final query = event.query.toLowerCase().trim();
    if (query.isEmpty) {
      _emitLoadedState(emit, searchQuery: '', searchResults: _allSales);
      return;
    }

    final filtered = _allSales.where((sale) {
      final nameMatch = sale.itemName.toLowerCase().contains(query);
      final partMatch = sale.productId.toLowerCase().contains(query);
      final codeMatch = sale.costCode.toLowerCase().contains(query);
      final dateMatch = sale.saleDate.toString().contains(query);
      final invoiceMatch = sale.invoiceId.toLowerCase().contains(query);

      return nameMatch ||
          partMatch ||
          codeMatch ||
          dateMatch ||
          invoiceMatch;
    }).toList();

    _emitLoadedState(
      emit,
      searchQuery: event.query,
      searchResults: filtered,
    );
  }

  void _onAddToCart(
    AddToCartEvent event,
    Emitter<PosState> emit,
  ) {
    // Prevent adding out-of-stock items (stock <= 0) to cart
    if (event.availableStock <= 0) {
      return;
    }

    // Each unique batch (identified by unique productId & partNo) is its own separate cart line item
    final existingIndex = _cartItems.indexWhere(
      (item) =>
          item.productId == event.productId && item.partNo == event.partNo,
    );

    if (existingIndex >= 0) {
      final existing = _cartItems[existingIndex];
      // Do not allow quantity in cart to exceed available batch stock
      if (existing.quantity >= event.availableStock) {
        return;
      }
      _cartItems[existingIndex] = existing.copyWith(
        quantity: existing.quantity + 1,
      );
    } else {
      _cartItems.add(
        CartItem(
          id: '${DateTime.now().microsecondsSinceEpoch}_${event.productId}_${event.partNo}',
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
          final maxStock =
              item.availableStock > 0 ? item.availableStock : item.quantity;
          final validQty =
              event.quantity > maxStock ? maxStock : event.quantity;
          return item.copyWith(quantity: validQty);
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
        return item.copyWith(sellPrice: event.sellPrice);
      }
      return item;
    }).toList();
    _emitLoadedState(emit);
  }

  void _onUpdateCartCostCode(
    UpdateCartCostCodeEvent event,
    Emitter<PosState> emit,
  ) {
    _cartItems = _cartItems.map((item) {
      if (item.id == event.cartItemId) {
        return item.copyWith(costCode: event.costCode);
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
        final maxStock =
            event.availableStock > 0 ? event.availableStock : 1;
        final validQty =
            item.quantity > maxStock ? maxStock : item.quantity;

        return item.copyWith(
          productId: event.productId,
          partNo: event.partNo,
          itemName: event.itemName,
          costCode: event.costCode,
          availableStock: event.availableStock,
          quantity: validQty,
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

    final salesList = checkoutItems
        .map(
          (item) => SaleEntity(
            id: '${DateTime.now().microsecondsSinceEpoch}_${item.productId.replaceAll('/', '_')}',
            productId: item.productId,
            partNo: item.partNo,
            saleDate: now,
            itemName: item.itemName,
            quantity: item.quantity,
            sellPrice: item.sellPrice,
            costCode: item.costCode,
            invoiceId: invoiceId,
          ),
        )
        .toList();

    // High-Performance Single-Transaction Atomic Checkout
    final result = await checkoutCart(
      sales: salesList,
      invoice: invoice,
    );

    result.fold(
      (failure) => emit(PosError(failure.message)),
      (_) {
        final oldCart = List<CartItem>.from(_cartItems);
        _cartItems = [];
        getSales().then((salesResult) {
          salesResult.fold(
            (_) {},
            (sales) => _allSales = sales,
          );
        });

        emit(SaleAddedSuccess(
          checkoutCartItems: oldCart,
          totalPaid: totalPaid,
          invoice: invoice,
          generatePdf: event.generatePdf,
          message: event.generatePdf
              ? 'Sale completed & bill generated!'
              : 'Sale recorded successfully without bill.',
        ));
      },
    );
  }
}
