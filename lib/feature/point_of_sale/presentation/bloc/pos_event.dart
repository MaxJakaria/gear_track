part of 'pos_bloc.dart';

sealed class PosEvent extends Equatable {
  const PosEvent();

  @override
  List<Object?> get props => [];
}

class LoadSalesEvent extends PosEvent {
  const LoadSalesEvent();
}

class FetchSalesEvent extends PosEvent {
  const FetchSalesEvent();
}

class FetchProductSalesEvent extends PosEvent {
  final String productId;

  const FetchProductSalesEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}

class AddSaleEvent extends PosEvent {
  final SaleEntity sale;

  const AddSaleEvent(this.sale);

  @override
  List<Object?> get props => [sale];
}

class SearchSalesEvent extends PosEvent {
  final String query;

  const SearchSalesEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class AddToCartEvent extends PosEvent {
  final String productId;
  final String batchId;
  final String itemName;
  final String partNo;
  final String costCode;
  final int availableStock;

  const AddToCartEvent({
    required this.productId,
    this.batchId = '',
    required this.itemName,
    required this.partNo,
    required this.costCode,
    required this.availableStock,
  });

  @override
  List<Object?> get props =>
      [productId, batchId, itemName, partNo, costCode, availableStock];
}

class UpdateCartQuantityEvent extends PosEvent {
  final String cartItemId;
  final int quantity;

  const UpdateCartQuantityEvent({
    required this.cartItemId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [cartItemId, quantity];
}

class UpdateCartPriceEvent extends PosEvent {
  final String cartItemId;
  final double sellPrice;

  const UpdateCartPriceEvent({
    required this.cartItemId,
    double? sellPrice,
    double? price,
  }) : sellPrice = sellPrice ?? price ?? 0.0;

  double get price => sellPrice;

  @override
  List<Object?> get props => [cartItemId, sellPrice];
}

class UpdateCartCostCodeEvent extends PosEvent {
  final String cartItemId;
  final String costCode;

  const UpdateCartCostCodeEvent({
    required this.cartItemId,
    required this.costCode,
  });

  @override
  List<Object?> get props => [cartItemId, costCode];
}

class UpdateCartProductEvent extends PosEvent {
  final String cartItemId;
  final String productId;
  final String batchId;
  final String partNo;
  final String itemName;
  final String costCode;
  final int availableStock;

  const UpdateCartProductEvent({
    required this.cartItemId,
    required this.productId,
    this.batchId = '',
    required this.partNo,
    required this.itemName,
    required this.costCode,
    required this.availableStock,
  });

  @override
  List<Object?> get props => [
        cartItemId,
        productId,
        batchId,
        partNo,
        itemName,
        costCode,
        availableStock,
      ];
}

class RemoveCartItemEvent extends PosEvent {
  final String cartItemId;

  const RemoveCartItemEvent(this.cartItemId);

  @override
  List<Object?> get props => [cartItemId];
}

class ClearCartEvent extends PosEvent {
  const ClearCartEvent();
}

class CheckoutCartEvent extends PosEvent {
  final bool generatePdf;
  final String partyName;
  final String partyAddress;
  final String servedBy;
  final double? paidAmount;
  final double? dueAmount;

  const CheckoutCartEvent({
    this.generatePdf = true,
    this.partyName = '',
    this.partyAddress = '',
    this.servedBy = '',
    this.paidAmount,
    this.dueAmount,
  });

  @override
  List<Object?> get props => [
    generatePdf,
    partyName,
    partyAddress,
    servedBy,
    paidAmount,
    dueAmount,
  ];
}

class SyncCartWithInventoryEvent extends PosEvent {
  final List<Product> products;

  const SyncCartWithInventoryEvent(this.products);

  @override
  List<Object?> get props => [products];
}
