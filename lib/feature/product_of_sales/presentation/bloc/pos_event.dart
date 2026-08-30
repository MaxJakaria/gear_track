part of 'pos_bloc.dart';

sealed class PosEvent extends Equatable {
  const PosEvent();

  @override
  List<Object?> get props => [];
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
  final String itemName;
  final String partNo;
  final String costCode;
  final int availableStock;

  const AddToCartEvent({
    required this.productId,
    required this.itemName,
    required this.partNo,
    required this.costCode,
    required this.availableStock,
  });

  @override
  List<Object?> get props => [productId, itemName, partNo, costCode, availableStock];
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
  final double price;

  const UpdateCartPriceEvent({
    required this.cartItemId,
    required this.price,
  });

  @override
  List<Object?> get props => [cartItemId, price];
}

class UpdateCartProductEvent extends PosEvent {
  final String cartItemId;
  final String productId;
  final String partNo;
  final String itemName;
  final String costCode;
  final int availableStock;

  const UpdateCartProductEvent({
    required this.cartItemId,
    required this.productId,
    required this.partNo,
    required this.itemName,
    required this.costCode,
    required this.availableStock,
  });

  @override
  List<Object?> get props => [
        cartItemId,
        productId,
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
  const CheckoutCartEvent();
}
