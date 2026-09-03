import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/domain/usecases/get_shop_settings.dart';
import 'package:gear_track/core/entities/shop_settings.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:gear_track/feature/point_of_sale/presentation/bloc/pos_bloc.dart';
import 'package:gear_track/feature/point_of_sale/presentation/pages/pdf_preview_page.dart';
import 'package:gear_track/feature/point_of_sale/presentation/widgets/pos_cart_card.dart';
import 'package:gear_track/feature/point_of_sale/presentation/widgets/pos_product_search_card.dart';
import 'package:gear_track/feature/point_of_sale/utils/pdf_receipt_service.dart';
import 'package:gear_track/feature/receipt_verification/presentation/pages/receipt_verification_page.dart';
import 'package:gear_track/feature/returns/presentation/pages/returns_page.dart';
import 'package:gear_track/init_dependencies.dart';

/// Point of Sale (POS) Primary Screen Page
class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    // Initial fetch for inventory products and sales data
    context.read<InventoryBloc>().add(const FetchProductsEvent());
    context.read<PosBloc>().add(const FetchSalesEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<PosBloc, PosState>(
      listener: (context, state) async {
        if (state is SaleAddedSuccess) {
          if (state.generatePdf && state.checkoutCartItems.isNotEmpty) {
            if (mounted) {
              setState(() {
                _isGeneratingPdf = true;
              });
            }

            ShopSettings shopSettings = const ShopSettings();
            try {
              final getShopSettings = serviceLocator<GetShopSettings>();
              final result = await getShopSettings();
              result.fold((_) {}, (settings) => shopSettings = settings);
            } catch (_) {}

            try {
              final doc = await PdfReceiptService.generateReceipt(
                state.checkoutCartItems,
                state.totalPaid,
                shopSettings: shopSettings,
                invoice: state.invoice,
              );
              final bytes = await doc.save();

              if (mounted) {
                setState(() {
                  _isGeneratingPdf = false;
                });
              }

              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PdfPreviewPage(pdfBytes: bytes),
                ),
              );
            } catch (e) {
              if (mounted) {
                setState(() {
                  _isGeneratingPdf = false;
                });
              }
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to generate PDF: $e'),
                  backgroundColor: const Color(0xFFD32F2F),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } else {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.message,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else if (state is PosError) {
          if (mounted) {
            setState(() {
              _isGeneratingPdf = false;
            });
          }
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFD32F2F),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final isBusy = state is SaleAdding || _isGeneratingPdf;

        return Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                title: const Text(
                  'Sales & Billing',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.assignment_return_rounded),
                    tooltip: 'Returns & Refunds',
                    onPressed: isBusy
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReturnsPage(),
                            ),
                          ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    tooltip: 'Verify Receipt',
                    onPressed: isBusy
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReceiptVerificationPage(),
                            ),
                          ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
              body: AbsorbPointer(
                absorbing: isBusy,
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // 1. "Find & Add Product" Component
                      PosProductSearchCard(
                        onProductSelected: (selectedBatch) {
                          final cleanProductId = selectedBatch.partNo.isNotEmpty
                              ? selectedBatch.partNo
                              : (selectedBatch.id.contains('/')
                                  ? selectedBatch.id.split('/')[0]
                                  : selectedBatch.id);
                          final batchId = selectedBatch.id.contains('/')
                              ? selectedBatch.id.split('/')[1]
                              : selectedBatch.id;

                          context.read<PosBloc>().add(
                            AddToCartEvent(
                              productId: cleanProductId,
                              batchId: batchId,
                              itemName: selectedBatch.itemName,
                              partNo: selectedBatch.partNo,
                              costCode: selectedBatch.costCode,
                              availableStock: selectedBatch.stockCount,
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

            // Non-Dismissible Processing & PDF Generation Modal Overlay
            if (isBusy)
              PopScope(
                canPop: false,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.55),
                  alignment: Alignment.center,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 22,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.4 : 0.15,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.5,
                            strokeCap: StrokeCap.round,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF6366F1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _isGeneratingPdf
                              ? 'Generating PDF Receipt...'
                              : 'Processing Transaction...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Saving sale records and building receipt',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
