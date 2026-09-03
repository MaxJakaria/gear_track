part of 'pos_bloc.dart';

sealed class PosState extends Equatable {
  const PosState();

  @override
  List<Object?> get props => [];
}

final class PosInitial extends PosState {}

final class PosLoading extends PosState {}

final class PosLoaded extends PosState {
  final List<SaleEntity> sales;
  final List<SaleEntity> filteredSales;
  final List<CartItem> cartItems;
  final String searchQuery;

  const PosLoaded({
    required this.sales,
    required this.filteredSales,
    this.cartItems = const [],
    this.searchQuery = '',
  });

  double get totalAmount => cartItems.fold(0.0, (total, item) => total + item.subtotal);
  int get totalItemCount => cartItems.fold(0, (total, item) => total + item.quantity);

  PosLoaded copyWith({
    List<SaleEntity>? sales,
    List<SaleEntity>? filteredSales,
    List<CartItem>? cartItems,
    String? searchQuery,
  }) {
    return PosLoaded(
      sales: sales ?? this.sales,
      filteredSales: filteredSales ?? this.filteredSales,
      cartItems: cartItems ?? this.cartItems,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [sales, filteredSales, cartItems, searchQuery];
}

final class SaleAdding extends PosState {}

final class SaleAddedSuccess extends PosState {
  final List<CartItem> checkoutCartItems;
  final double totalPaid;
  final String message;
  final InvoiceEntity? invoice;
  final bool generatePdf;

  const SaleAddedSuccess({
    this.checkoutCartItems = const [],
    this.totalPaid = 0.0,
    this.message = 'Sale recorded successfully!',
    this.invoice,
    this.generatePdf = true,
  });

  @override
  List<Object?> get props =>
      [checkoutCartItems, totalPaid, message, invoice, generatePdf];
}

final class PosError extends PosState {
  final String message;

  const PosError(this.message);

  @override
  List<Object?> get props => [message];
}
