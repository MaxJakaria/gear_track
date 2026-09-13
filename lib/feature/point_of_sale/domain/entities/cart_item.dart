import 'package:equatable/equatable.dart';

class CartItem extends Equatable {
  final String id;
  final String productId;
  final String batchId;
  final String itemName;
  final String partNo;
  final String costCode;
  final int availableStock;
  final int quantity;
  final double sellPrice;

  const CartItem({
    required this.id,
    required this.productId,
    this.batchId = '',
    required this.itemName,
    required this.partNo,
    required this.costCode,
    required this.availableStock,
    this.quantity = 1,
    this.sellPrice = 0.0,
  });

  double get subtotal => quantity * sellPrice;

  CartItem copyWith({
    String? productId,
    String? batchId,
    String? itemName,
    String? partNo,
    String? costCode,
    int? availableStock,
    int? quantity,
    double? sellPrice,
  }) {
    return CartItem(
      id: id,
      productId: productId ?? this.productId,
      batchId: batchId ?? this.batchId,
      itemName: itemName ?? this.itemName,
      partNo: partNo ?? this.partNo,
      costCode: costCode ?? this.costCode,
      availableStock: availableStock ?? this.availableStock,
      quantity: quantity ?? this.quantity,
      sellPrice: sellPrice ?? this.sellPrice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'batchId': batchId,
      'itemName': itemName,
      'partNo': partNo,
      'costCode': costCode,
      'availableStock': availableStock,
      'quantity': quantity,
      'sellPrice': sellPrice,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      batchId: map['batchId'] ?? '',
      itemName: map['itemName'] ?? '',
      partNo: map['partNo'] ?? '',
      costCode: map['costCode'] ?? '',
      availableStock: (map['availableStock'] as num?)?.toInt() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      sellPrice: (map['sellPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    batchId,
    itemName,
    partNo,
    costCode,
    availableStock,
    quantity,
    sellPrice,
  ];
}
