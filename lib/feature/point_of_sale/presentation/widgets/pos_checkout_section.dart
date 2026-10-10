import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/feature/point_of_sale/presentation/bloc/pos_bloc.dart';
import 'package:gear_track/feature/point_of_sale/presentation/widgets/pos_checkout_button.dart';

/// Section for Customer / Party Details, Payment/Due Input, and Checkout Action
class PosCheckoutSection extends StatefulWidget {
  const PosCheckoutSection({super.key});

  @override
  State<PosCheckoutSection> createState() => _PosCheckoutSectionState();
}

class _PosCheckoutSectionState extends State<PosCheckoutSection> {
  late final TextEditingController _partyNameController;
  late final TextEditingController _partyAddressController;
  late final TextEditingController _servedByController;
  late final TextEditingController _paidAmountController;

  @override
  void initState() {
    super.initState();
    _partyNameController = TextEditingController();
    _partyAddressController = TextEditingController();
    _servedByController = TextEditingController();
    _paidAmountController = TextEditingController();
    _paidAmountController.addListener(_onInputChanged);
    _partyNameController.addListener(_onInputChanged);
    _partyAddressController.addListener(_onInputChanged);
    _servedByController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _paidAmountController.removeListener(_onInputChanged);
    _partyNameController.removeListener(_onInputChanged);
    _partyAddressController.removeListener(_onInputChanged);
    _servedByController.removeListener(_onInputChanged);
    _partyNameController.dispose();
    _partyAddressController.dispose();
    _servedByController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  void _clearInputs() {
    _partyNameController.clear();
    _partyAddressController.clear();
    _servedByController.clear();
    _paidAmountController.clear();
  }

  double _getPaidAmount(double totalAmount) {
    final text = _paidAmountController.text.trim();
    if (text.isEmpty) return totalAmount;
    final val = double.tryParse(text);
    if (val == null || val < 0) return totalAmount;
    return val;
  }

  double _getDueAmount(double totalAmount) {
    final paid = _getPaidAmount(totalAmount);
    final due = totalAmount - paid;
    return due > 0 ? due : 0.0;
  }

  void _handleCheckout(
    BuildContext context,
    bool generatePdf,
    double totalAmount,
  ) {
    final paid = _getPaidAmount(totalAmount);
    final due = _getDueAmount(totalAmount);
    final hasDue = due > 0;

    final partyName = _partyNameController.text.trim();
    final partyAddress = _partyAddressController.text.trim();
    final servedBy = _servedByController.text.trim();

    if (hasDue) {
      if (partyName.isEmpty) {
        _showValidationAlert('Party Name is required when selling with due.');
        return;
      }
    }

    context.read<PosBloc>().add(
      CheckoutCartEvent(
        generatePdf: generatePdf,
        partyName: partyName,
        partyAddress: partyAddress,
        servedBy: servedBy,
        paidAmount: paid,
        dueAmount: due,
      ),
    );
  }

  void _showValidationAlert(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
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

          final paid = _getPaidAmount(totalAmount);
          final due = _getDueAmount(totalAmount);
          final hasDue = due > 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Payment & Due Section + Customer Details
              _buildPaymentAndCustomerSection(
                theme,
                isDark,
                totalAmount,
                paid,
                due,
                hasDue,
              ),

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

              // 2. Checkout Buttons (Sale Only & Generate Bill)
              PosCheckoutButton(
                cartItems: List.from(cartItems),
                totalAmount: totalAmount,
                paidAmount: paid,
                dueAmount: due,
                isLoading: isProcessing,
                isEnabled: !hasStockIssue,
                partyNameController: _partyNameController,
                partyAddressController: _partyAddressController,
                servedByController: _servedByController,
                onCheckout: (bool generatePdf) =>
                    _handleCheckout(context, generatePdf, totalAmount),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentAndCustomerSection(
    ThemeData theme,
    bool isDark,
    double totalAmount,
    double paid,
    double due,
    bool hasDue,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155).withValues(alpha: 0.6)
              : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Paid & Due Input Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Paid Amount Field
              Expanded(
                child: _buildCompactInput(
                  controller: _paidAmountController,
                  label: 'Paid Amount',
                  isDark: isDark,
                  theme: theme,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  hintText: '৳${totalAmount.toStringAsFixed(0)}',
                ),
              ),

              // Due text only if due exists (no container background)
              if (hasDue) ...[
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Due: ৳${due.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),

          // Customer Fields
          _buildCompactInput(
            controller: _partyNameController,
            label: 'Party Name',
            isRequired: hasDue,
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: 8),
          _buildCompactInput(
            controller: _partyAddressController,
            label: 'Party Address',
            isRequired: false,
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: 8),
          _buildCompactInput(
            controller: _servedByController,
            label: 'Served By',
            isRequired: false,
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
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 3),
              const Text(
                '*',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 3),
        SizedBox(
          height: 36,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: hintText,
              hintStyle: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
              ),
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
