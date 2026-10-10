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
  final bool isEnabled;
  final String partyName;
  final String partyAddress;
  final String servedBy;
  final double? paidAmount;
  final double? dueAmount;
  final TextEditingController? partyNameController;
  final TextEditingController? partyAddressController;
  final TextEditingController? servedByController;
  final void Function(bool generatePdf)? onCheckout;

  const PosCheckoutButton({
    super.key,
    required this.cartItems,
    required this.totalAmount,
    this.isLoading = false,
    this.isEnabled = true,
    this.partyName = '',
    this.partyAddress = '',
    this.servedBy = '',
    this.paidAmount,
    this.dueAmount,
    this.partyNameController,
    this.partyAddressController,
    this.servedByController,
    this.onCheckout,
  });

  String _getPartyName() => partyNameController?.text.trim() ?? partyName.trim();
  String _getPartyAddress() => partyAddressController?.text.trim() ?? partyAddress.trim();
  String _getServedBy() => servedByController?.text.trim() ?? servedBy.trim();

  void _handleCheckout(BuildContext context, bool generatePdf) {
    if (onCheckout != null) {
      onCheckout!(generatePdf);
      return;
    }
    context.read<PosBloc>().add(
      CheckoutCartEvent(
        generatePdf: generatePdf,
        partyName: _getPartyName(),
        partyAddress: _getPartyAddress(),
        servedBy: _getServedBy(),
        paidAmount: paidAmount,
        dueAmount: dueAmount,
      ),
    );
  }

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
            onPressed:
                (isLoading || !isEnabled) ? null : () => _handleCheckout(context, false),
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
            onPressed:
                (isLoading || !isEnabled) ? null : () => _handleCheckout(context, true),
          ),
        ),
      ],
    );
  }
}
