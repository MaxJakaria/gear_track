import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/widgets/app_gradient_button.dart';
import 'package:gear_track/feature/point_of_sale/domain/entities/cart_item.dart';
import 'package:gear_track/feature/point_of_sale/presentation/bloc/pos_bloc.dart';

/// Two-Action POS Checkout Buttons Widget using the shared [AppGradientButton] widget
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
    return Row(
      children: [
        // 1. "Sale Only" Button
        Expanded(
          child: AppGradientButton(
            label: 'Sale Only',
            icon: Icons.check_circle_rounded,
            isLoading: isLoading,
            height: 48,
            borderRadius: 8,
            onPressed: isLoading
                ? null
                : () {
                    context.read<PosBloc>().add(
                      const CheckoutCartEvent(generatePdf: false),
                    );
                  },
          ),
        ),

        const SizedBox(width: 12),

        // 2. "Generate Bill" Button
        Expanded(
          child: AppGradientButton(
            label: 'Generate Bill',
            icon: Icons.receipt_long_rounded,
            isLoading: isLoading,
            height: 48,
            borderRadius: 8,
            onPressed: isLoading
                ? null
                : () {
                    context.read<PosBloc>().add(
                      const CheckoutCartEvent(generatePdf: true),
                    );
                  },
          ),
        ),
      ],
    );
  }
}
