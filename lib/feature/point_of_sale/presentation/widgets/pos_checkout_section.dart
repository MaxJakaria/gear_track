import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/feature/point_of_sale/presentation/bloc/pos_bloc.dart';
import 'package:gear_track/feature/point_of_sale/presentation/widgets/pos_checkout_button.dart';

/// Section for Customer / Party Details and Checkout Action
class PosCheckoutSection extends StatefulWidget {
  const PosCheckoutSection({super.key});

  @override
  State<PosCheckoutSection> createState() => _PosCheckoutSectionState();
}

class _PosCheckoutSectionState extends State<PosCheckoutSection> {
  late final TextEditingController _partyNameController;
  late final TextEditingController _partyAddressController;
  late final TextEditingController _servedByController;

  @override
  void initState() {
    super.initState();
    _partyNameController = TextEditingController();
    _partyAddressController = TextEditingController();
    _servedByController = TextEditingController();
  }

  @override
  void dispose() {
    _partyNameController.dispose();
    _partyAddressController.dispose();
    _servedByController.dispose();
    super.dispose();
  }

  void _clearInputs() {
    _partyNameController.clear();
    _partyAddressController.clear();
    _servedByController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<PosBloc, PosState>(
      listenWhen: (prev, current) => current is SaleAddedSuccess,
      listener: (context, state) => _clearInputs(),
      child: BlocBuilder<PosBloc, PosState>(
        builder: (context, state) {
          final cartItems = state is PosLoaded ? state.cartItems : const [];
          final totalAmount = state is PosLoaded ? state.totalAmount : 0.0;
          final isProcessing = state is SaleAdding;

          if (cartItems.isEmpty) {
            return const SizedBox.shrink();
          }

          final hasOutOfStockItems = cartItems.any(
            (item) => item.availableStock <= 0,
          );
          final hasExcessQuantityItems = cartItems.any(
            (item) =>
                item.availableStock > 0 && item.quantity > item.availableStock,
          );
          final hasStockIssue = hasOutOfStockItems || hasExcessQuantityItems;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Customer / Party Details Section
              _buildOptionalPartySection(theme, isDark),

              const SizedBox(height: 12),

              // Stock Warning Banner if any cart item is out of stock or exceeds stock
              if (hasStockIssue) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hasOutOfStockItems
                              ? 'Some items in the cart are out of stock. Please remove them before checkout.'
                              : 'Some item quantities exceed available stock. Please adjust quantities before checkout.',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 3. Checkout Buttons (Sale Only & Generate Bill)
              PosCheckoutButton(
                cartItems: List.from(cartItems),
                totalAmount: totalAmount,
                isLoading: isProcessing,
                isEnabled: !hasStockIssue,
                partyNameController: _partyNameController,
                partyAddressController: _partyAddressController,
                servedByController: _servedByController,
                onCheckout: (bool generatePdf) {
                  context.read<PosBloc>().add(
                    CheckoutCartEvent(
                      generatePdf: generatePdf,
                      partyName: _partyNameController.text.trim(),
                      partyAddress: _partyAddressController.text.trim(),
                      servedBy: _servedByController.text.trim(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOptionalPartySection(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompactInput(
            controller: _partyNameController,
            label: 'Party Name (Optional)',
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: 8),
          _buildCompactInput(
            controller: _partyAddressController,
            label: 'Party Address (Optional)',
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: 8),
          _buildCompactInput(
            controller: _servedByController,
            label: 'Served By (Optional)',
            isDark: isDark,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInput({
    required TextEditingController controller,
    required String label,
    required bool isDark,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 3),
        SizedBox(
          height: 36,
          child: TextField(
            controller: controller,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              filled: true,
              fillColor: isDark
                  ? theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    )
                  : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.8,
                  ),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.8,
                  ),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 1.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
