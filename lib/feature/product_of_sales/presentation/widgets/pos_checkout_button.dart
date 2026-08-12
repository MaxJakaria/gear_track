import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/feature/product_of_sales/domain/entities/cart_item.dart';
import 'package:gear_track/feature/product_of_sales/presentation/bloc/pos_bloc.dart';
import 'package:gear_track/feature/product_of_sales/presentation/widgets/bill_receipt_modal.dart';

/// Primary "Generate PDF for Bill" Checkout Button Widget
class PosCheckoutButton extends StatelessWidget {
  final List<CartItem> cartItems;
  final double totalAmount;

  const PosCheckoutButton({
    super.key,
    required this.cartItems,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00A859), // Vibrant green
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: const Color(0xFF00A859).withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          BillReceiptModal.show(
            context,
            cartItems: List.from(cartItems),
            totalAmount: totalAmount,
            onConfirmSale: () {
              context.read<PosBloc>().add(const CheckoutCartEvent());
            },
          );
        },
        icon: const Icon(Icons.print_outlined, size: 20),
        label: const Text(
          'Generate PDF for Bill',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
