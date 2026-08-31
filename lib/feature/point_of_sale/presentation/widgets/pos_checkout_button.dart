import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/theme/app_colors.dart';
import 'package:gear_track/feature/point_of_sale/domain/entities/cart_item.dart';
import 'package:gear_track/feature/point_of_sale/presentation/bloc/pos_bloc.dart';

/// Primary "Generate PDF for Bill" Linear Gradient Checkout Button Widget
class PosCheckoutButton extends StatelessWidget {
  final List<CartItem> cartItems;
  final double totalAmount;
  final bool isLoading;

  const PosCheckoutButton({
    super.key,
    required this.cartItems,
    required this.totalAmount,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = AppColors.primaryGradient(context);
    final primaryColor = AppColors.primaryButton(context);

    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isLoading
              ? null
              : () {
                  context.read<PosBloc>().add(const CheckoutCartEvent());
                },
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                else
                  const Icon(Icons.print_outlined, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  isLoading ? 'Processing...' : 'Generate PDF for Bill',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
