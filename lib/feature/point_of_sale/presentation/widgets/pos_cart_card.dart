import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/feature/point_of_sale/domain/entities/cart_item.dart';
import 'package:gear_track/core/utils/currency_formatter.dart';
import 'package:gear_track/feature/point_of_sale/presentation/bloc/pos_bloc.dart';
import 'package:gear_track/feature/point_of_sale/presentation/pages/pdf_preview_page.dart';
import 'package:gear_track/feature/point_of_sale/presentation/widgets/pos_cart_empty_view.dart';
import 'package:gear_track/feature/point_of_sale/presentation/widgets/pos_cart_item_tile.dart';
import 'package:gear_track/feature/point_of_sale/presentation/widgets/pos_checkout_button.dart';

import 'package:gear_track/init_dependencies.dart';
import 'package:gear_track/core/domain/usecases/get_shop_settings.dart';
import 'package:gear_track/core/entities/shop_settings.dart';
import 'package:gear_track/feature/point_of_sale/utils/pdf_receipt_service.dart';

/// "Sales Cart" Card Component
class PosCartCard extends StatefulWidget {
  const PosCartCard({super.key});

  @override
  State<PosCartCard> createState() => _PosCartCardState();
}

class _PosCartCardState extends State<PosCartCard> {
  bool _isPdfGenerating = false;
  List<CartItem> _currentCartItems = [];
  double _currentTotal = 0.0;
  int _currentItemCount = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<PosBloc, PosState>(
      listener: (context, state) async {
        if (state is SaleAddedSuccess && state.checkoutCartItems.isNotEmpty) {
          if (mounted) {
            setState(() {
              _isPdfGenerating = true;
            });
          }
          ShopSettings shopSettings = const ShopSettings();
          try {
            final getShopSettings = serviceLocator<GetShopSettings>();
            final result = await getShopSettings();
            result.fold((_) {}, (settings) => shopSettings = settings);
          } catch (_) {}

          final doc = await PdfReceiptService.generateReceipt(
            state.checkoutCartItems,
            state.totalPaid,
            shopSettings: shopSettings,
            invoice: state.invoice,
          );
          final bytes = await doc.save();
          if (mounted) {
            setState(() {
              _isPdfGenerating = false;
            });
          }
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PdfPreviewPage(pdfBytes: bytes),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is PosLoaded && !_isPdfGenerating) {
          _currentCartItems = state.cartItems;
          _currentTotal = state.totalAmount;
          _currentItemCount = state.totalItemCount;
        }

        final cartItems = _currentCartItems;
        final totalAmount = _currentTotal;
        final itemCount = _currentItemCount;

        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Green Pill + Sales Cart Title + Item Count Badge
              _buildHeader(theme, itemCount),

              const SizedBox(height: 16),

              // Cart Items List / Empty View
              if (cartItems.isEmpty)
                const PosCartEmptyView()
              else
                Column(
                  children: cartItems.map((item) {
                    return PosCartItemTile(
                      key: ValueKey(item.id),
                      item: item,
                      onQuantityChanged: (newQty) {
                        context.read<PosBloc>().add(
                          UpdateCartQuantityEvent(
                            cartItemId: item.id,
                            quantity: newQty,
                          ),
                        );
                      },
                      onPriceChanged: (newPrice) {
                        context.read<PosBloc>().add(
                          UpdateCartPriceEvent(
                            cartItemId: item.id,
                            price: newPrice,
                          ),
                        );
                      },
                      onProductChanged: (selectedBatch) {
                        context.read<PosBloc>().add(
                          UpdateCartProductEvent(
                            cartItemId: item.id,
                            productId: selectedBatch.partNo,
                            partNo: selectedBatch.partNo,
                            itemName: selectedBatch.itemName,
                            costCode: selectedBatch.costCode,
                            availableStock: selectedBatch.stockCount,
                          ),
                        );
                      },
                      removeItem: () {
                        context.read<PosBloc>().add(
                          RemoveCartItemEvent(item.id),
                        );
                      },
                    );
                  }).toList(),
                ),

              // Summary Footer & Checkout Button
              if (cartItems.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                    height: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                Text(
                  'TOTAL AMOUNT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalAmount.toCurrency(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                PosCheckoutButton(
                  cartItems: List.from(cartItems),
                  totalAmount: totalAmount,
                  isLoading: state is SaleAdding || _isPdfGenerating,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme, int itemCount) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF00A859), // Green pill
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Sales Cart',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Text(
            '$itemCount',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
