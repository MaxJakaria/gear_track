import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gear_track/core/domain/usecases/get_shop_settings.dart';
import 'package:gear_track/core/entities/shop_settings.dart';
import 'package:gear_track/feature/inventory/domain/entities/product.dart';
import 'package:gear_track/feature/point_of_sale/domain/entities/cart_item.dart';
import 'package:gear_track/feature/point_of_sale/domain/entities/sale_entity.dart';
import 'package:gear_track/feature/point_of_sale/domain/usecases/add_sale.dart';
import 'package:gear_track/feature/point_of_sale/domain/usecases/checkout_cart.dart';
import 'package:gear_track/feature/point_of_sale/domain/usecases/get_product_sales.dart';
import 'package:gear_track/feature/point_of_sale/domain/usecases/get_sales.dart';
import 'package:gear_track/feature/point_of_sale/domain/usecases/save_invoice.dart';
import 'package:gear_track/feature/point_of_sale/utils/pdf_receipt_service.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';
import 'package:gear_track/init_dependencies.dart';

part 'pos_event.dart';
part 'pos_state.dart';

class PosBloc extends Bloc<PosEvent, PosState> {
  static const String _cartStorageKey = 'pos_saved_cart_items_v1';

  final GetSales getSales;
  final AddSale addSale;
  final CheckoutCart checkoutCart;
  final GetProductSales getProductSales;
  final SaveInvoice saveInvoice;

  List<CartItem> _cartItems = [];
  List<SaleEntity> _allSales = [];
  bool _hasLoadedSavedCart = false;

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
    on<SyncCartWithInventoryEvent>(_onSyncCartWithInventory);
  }

  Future<void> _ensureCartLoaded() async {
    if (_hasLoadedSavedCart) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cartStorageKey);
      if (raw != null && raw.isNotEmpty && _cartItems.isEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        _cartItems = list
            .map((e) => CartItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {}
    _hasLoadedSavedCart = true;
  }

  void _saveCartToStorage() {
    SharedPreferences.getInstance()
        .then((prefs) {
          if (_cartItems.isEmpty) {
            prefs.remove(_cartStorageKey);
          } else {
            final raw = jsonEncode(_cartItems.map((i) => i.toMap()).toList());
            prefs.setString(_cartStorageKey, raw);
          }
        })
        .catchError((_) {});
  }

  void _emitLoadedState(
    Emitter<PosState> emit, {
    String searchQuery = '',
    List<SaleEntity>? searchResults,
  }) {
    _saveCartToStorage();
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
    await _ensureCartLoaded();
    if (_allSales.isEmpty) emit(PosLoading());
    final salesResult = await getSales();

    salesResult.fold((failure) => emit(PosError(failure.message)), (sales) {
      _allSales = sales;
      _emitLoadedState(emit);
    });
  }

  Future<void> _onFetchSales(
    FetchSalesEvent event,
    Emitter<PosState> emit,
  ) async {
    await _ensureCartLoaded();
    if (_allSales.isEmpty) emit(PosLoading());
    final salesResult = await getSales();

    salesResult.fold((failure) => emit(PosError(failure.message)), (sales) {
      _allSales = sales;
      _emitLoadedState(emit);
    });
  }

  void _onSearchSales(SearchSalesEvent event, Emitter<PosState> emit) {
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

      return nameMatch || partMatch || codeMatch || dateMatch || invoiceMatch;
    }).toList();

    _emitLoadedState(emit, searchQuery: event.query, searchResults: filtered);
  }

  void _onAddToCart(AddToCartEvent event, Emitter<PosState> emit) {
    // Prevent adding out-of-stock items (stock <= 0) to cart
    if (event.availableStock <= 0) {
      return;
    }

    // Identify unique batch in cart by productId and batchId
    final existingIndex = _cartItems.indexWhere(
      (item) =>
          item.productId == event.productId && item.batchId == event.batchId,
    );

    if (existingIndex >= 0) {
      // Do not add duplicate row, and do not increment quantity
      return;
    }

    _cartItems.add(
      CartItem(
        id: '${DateTime.now().microsecondsSinceEpoch}_${event.partNo}_${event.batchId}',
        productId: event.productId,
        batchId: event.batchId,
        itemName: event.itemName,
        partNo: event.partNo,
        costCode: event.costCode,
        quantity: 1,
        sellPrice: 0.0,
        availableStock: event.availableStock,
      ),
    );

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
          final maxStock = item.availableStock > 0
              ? item.availableStock
              : item.quantity;
          final validQty = event.quantity > maxStock
              ? maxStock
              : event.quantity;
          return item.copyWith(quantity: validQty);
        }
        return item;
      }).toList();
    }
    _emitLoadedState(emit);
  }

  void _onUpdateCartPrice(UpdateCartPriceEvent event, Emitter<PosState> emit) {
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
        final maxStock = event.availableStock > 0 ? event.availableStock : 1;
        final validQty = item.quantity > maxStock ? maxStock : item.quantity;

        return item.copyWith(
          productId: event.productId,
          batchId: event.batchId,
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

  void _onRemoveCartItem(RemoveCartItemEvent event, Emitter<PosState> emit) {
    _cartItems = _cartItems.where((i) => i.id != event.cartItemId).toList();
    _emitLoadedState(emit);
  }

  void _onClearCart(ClearCartEvent event, Emitter<PosState> emit) {
    _cartItems = [];
    _emitLoadedState(emit);
  }

  void _onSyncCartWithInventory(
    SyncCartWithInventoryEvent event,
    Emitter<PosState> emit,
  ) {
    if (_cartItems.isEmpty) return;

    bool hasChanged = false;
    final updatedCart = <CartItem>[];

    for (final item in _cartItems) {
      final match = event.products.where((p) {
        if (item.batchId.isNotEmpty && p.id.contains('/')) {
          final bId = p.id.split('/')[1];
          if (bId == item.batchId) return true;
        }
        if (item.partNo.isNotEmpty &&
            p.partNo.trim().toUpperCase() == item.partNo.trim().toUpperCase()) {
          return true;
        }
        return p.id == item.productId;
      }).firstOrNull;

      final liveStock = match?.stockCount ?? 0;
      if (item.availableStock != liveStock) {
        hasChanged = true;
      }

      int newQty = item.quantity;
      if (liveStock > 0 && newQty > liveStock) {
        newQty = liveStock;
        hasChanged = true;
      }

      updatedCart.add(
        item.copyWith(availableStock: liveStock, quantity: newQty),
      );
    }

    if (hasChanged) {
      _cartItems = updatedCart;
      _emitLoadedState(emit);
    }
  }

  Future<void> _onCheckoutCart(
    CheckoutCartEvent event,
    Emitter<PosState> emit,
  ) async {
    if (_cartItems.isEmpty) return;

    emit(SaleAdding());

    final checkoutItems = List<CartItem>.from(_cartItems);
    final totalPaid = checkoutItems.fold(0.0, (total, i) => total + i.subtotal);
    final now = DateTime.now();

    // Invoice ID format: INV-yyyy-XXXXXX (6-digit auto count, resets each year)
    // e.g. INV-2026-000001
    int seq = 1;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('invoices')
          .count()
          .get()
          .timeout(const Duration(seconds: 2));
      seq = (snap.count ?? 0) + 1;
    } catch (_) {
      final thisYearInvoices = _allSales
          .where(
            (s) => s.saleDate.year == now.year && s.invoiceId.isNotEmpty,
          )
          .map((s) => s.invoiceId)
          .toSet();
      seq = thisYearInvoices.length + 1;
    }

    String seqStr = seq.toString().padLeft(6, '0');
    String invoiceId = 'INV-${now.year}-$seqStr';

    // Ensure collision-proof uniqueness against all known sales in memory
    final existingInvoices = _allSales.map((s) => s.invoiceId).toSet();
    while (existingInvoices.contains(invoiceId)) {
      seq++;
      seqStr = seq.toString().padLeft(6, '0');
      invoiceId = 'INV-${now.year}-$seqStr';
    }

    final invoiceItems = checkoutItems
        .map(
          (i) => InvoiceItemEntity(
            productId: i.productId,
            batchId: i.batchId,
            itemName: i.itemName,
            partNo: i.partNo,
            quantity: i.quantity,
            sellPrice: i.sellPrice,
            costCode: i.costCode,
          ),
        )
        .toList();

    // -------------------------------------------------------------------------
    // Load Shop Settings so invoice saved in Firestore includes full business details
    // -------------------------------------------------------------------------
    ShopSettings shopSettings = const ShopSettings();
    try {
      final getShopSettings = serviceLocator<GetShopSettings>();
      final result = await getShopSettings().timeout(
        const Duration(seconds: 2),
      );
      result.fold((_) {}, (settings) => shopSettings = settings);
    } catch (_) {}

    final totalBill = checkoutItems.fold(0.0, (total, i) => total + i.subtotal);
    final paidAmount = event.paidAmount ?? totalBill;
    final dueAmount = event.dueAmount ?? (totalBill - paidAmount).clamp(0.0, totalBill);
    final paymentStatus = dueAmount > 0
        ? (paidAmount > 0 ? 'PARTIAL' : 'DUE')
        : 'PAID';

    final invoice = InvoiceEntity(
      invoiceId: invoiceId,
      saleDate: now,
      totalAmount: totalBill,
      totalItems: checkoutItems.fold(0, (total, i) => total + i.quantity),
      items: invoiceItems,
      shopName: shopSettings.shopName,
      shopPhone: shopSettings.phone,
      shopAddress: shopSettings.address,
      shopEmail: shopSettings.email,
      partyName: event.partyName,
      partyAddress: event.partyAddress,
      servedBy: event.servedBy,
      paidAmount: paidAmount,
      dueAmount: dueAmount,
      paymentStatus: paymentStatus,
    );

    int itemIndex = 1;
    final nowMicros = now.microsecondsSinceEpoch;
    final salesList = checkoutItems
        .map(
          (item) => SaleEntity(
            id: 'REC-${now.year}-${seqStr}_${itemIndex++}_$nowMicros',
            productId: item.productId,
            batchId: item.batchId,
            partNo: item.partNo,
            saleDate: now,
            itemName: item.itemName,
            quantity: item.quantity,
            sellPrice: item.sellPrice,
            costCode: item.costCode,
            invoiceId: invoiceId,
            partyName: event.partyName,
            partyAddress: event.partyAddress,
            servedBy: event.servedBy,
          ),
        )
        .toList();

    // -------------------------------------------------------------------------
    // STEP 1: PRE-FLIGHT PDF GENERATION (Generate PDF in memory first)
    // -------------------------------------------------------------------------
    Uint8List? generatedPdfBytes;
    try {
      final doc = await PdfReceiptService.generateReceipt(
        checkoutItems,
        totalBill,
        shopSettings: shopSettings,
        invoice: invoice,
      ).timeout(const Duration(seconds: 6));
      generatedPdfBytes = await doc.save().timeout(
        const Duration(seconds: 4),
      );
    } catch (pdfError) {
      // If PDF generation fails, STOP immediately!
      // Do NOT touch Firestore database, do NOT clear cart items.
      emit(PosError('Failed to generate receipt PDF: $pdfError'));
      _emitLoadedState(emit);
      return;
    }

    // -------------------------------------------------------------------------
    // STEP 2: ATOMIC DATABASE TRANSACTION (Update database only after PDF success)
    // -------------------------------------------------------------------------
    final result = await checkoutCart(sales: salesList, invoice: invoice);

    result.fold(
      (failure) {
        // Database update failed: Cart remains intact, emit error
        emit(PosError(failure.message));
        _emitLoadedState(emit);
      },
      (_) {
        // Database update succeeded! Now clear cart and save local state
        final oldCart = List<CartItem>.from(_cartItems);
        _cartItems = [];
        _saveCartToStorage();
        // Optimistically prepend newly completed sales locally to save hundreds of Firestore reads
        _allSales = [...salesList, ..._allSales];

        emit(
          SaleAddedSuccess(
            checkoutCartItems: oldCart,
            totalPaid: totalPaid,
            invoice: invoice,
            generatePdf: event.generatePdf,
            pdfBytes: generatedPdfBytes,
            message: event.generatePdf
                ? 'Sale completed & bill generated!'
                : 'Sale recorded successfully without bill.',
          ),
        );
      },
    );
  }
}
