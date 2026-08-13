import 'package:equatable/equatable.dart';

class CartItem extends Equatable {
  final String id;
  final String productId;
  final String itemName;
  final String partNo;
  final String costCode;
  final int availableStock;
  final int quantity;
  final double sellPrice;

  const CartItem({
    required this.id,
    required this.productId,
    required this.itemName,
    required this.partNo,
    required this.costCode,
    required this.availableStock,
    this.quantity = 1,
    this.sellPrice = 0.0,
  });

  double get subtotal => quantity * sellPrice;

  CartItem copyWith({
    int? quantity,
    double? sellPrice,
  }) {
    return CartItem(
      id: id,
      productId: productId,
      itemName: itemName,
      partNo: partNo,
      costCode: costCode,
      availableStock: availableStock,
      quantity: quantity ?? this.quantity,
      sellPrice: sellPrice ?? this.sellPrice,
    );
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        itemName,
        partNo,
        costCode,
        availableStock,
        quantity,
        sellPrice,
      ];
}
