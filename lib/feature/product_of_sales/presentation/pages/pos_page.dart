import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:gear_track/feature/product_of_sales/presentation/bloc/pos_bloc.dart';
import 'package:gear_track/feature/product_of_sales/presentation/widgets/pos_cart_card.dart';
import 'package:gear_track/feature/product_of_sales/presentation/widgets/pos_product_search_card.dart';

/// Point of Sale (POS) Primary Screen Page
class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  @override
  void initState() {
    super.initState();
    // Initial fetch for inventory products and sales data
    context.read<InventoryBloc>().add(const FetchProductsEvent());
    context.read<PosBloc>().add(const FetchSalesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Sales & Billing',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        body: BlocListener<PosBloc, PosState>(
          listener: (context, state) {
            if (state is SaleAddedSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(child: Text(state.message)),
                    ],
                  ),
                  backgroundColor: const Color(0xFF00A859),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            } else if (state is PosError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: const Color(0xFFD32F2F),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 1. "Find & Add Product" Component
                PosProductSearchCard(
                  onProductSelected: (latestBatch, grouped) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    context.read<PosBloc>().add(
                      AddToCartEvent(
                        productId: grouped.partNo,
                        itemName: grouped.itemName,
                        partNo: grouped.partNo,
                        costCode: latestBatch.costCode,
                        availableStock: grouped.totalStockCount,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // 2. "Sales Cart" Component
                const PosCartCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
