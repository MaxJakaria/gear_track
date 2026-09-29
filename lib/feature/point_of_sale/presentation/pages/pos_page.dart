import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/widgets/app_gradient_button.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:gear_track/feature/point_of_sale/domain/entities/cart_item.dart';
import 'package:gear_track/feature/point_of_sale/presentation/bloc/pos_bloc.dart';
import 'package:gear_track/feature/point_of_sale/presentation/pages/pdf_preview_page.dart';
import 'package:gear_track/feature/point_of_sale/presentation/widgets/pos_cart_card.dart';
import 'package:gear_track/feature/point_of_sale/presentation/widgets/pos_checkout_section.dart';
import 'package:gear_track/feature/point_of_sale/presentation/widgets/pos_product_search_card.dart';
import 'package:gear_track/feature/point_of_sale/utils/pdf_receipt_service.dart';
import 'package:gear_track/feature/due_management/presentation/pages/due_management_page.dart';
import 'package:gear_track/feature/reports/presentation/bloc/reports_bloc.dart';
import 'package:gear_track/feature/returns/presentation/pages/returns_page.dart';

/// Point of Sale (POS) Primary Screen Page
class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  bool _isGeneratingPdf = false;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    if (_searchQuery.isNotEmpty) {
      setState(() {
        _searchQuery = '';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Always fetch latest products from Firestore on entering POS page
    final inventoryState = context.read<InventoryBloc>().state;
    if (inventoryState is InventoryLoaded) {
      context.read<PosBloc>().add(
        SyncCartWithInventoryEvent(inventoryState.products),
      );
    }
    context.read<InventoryBloc>().add(const FetchProductsEvent());
    context.read<PosBloc>().add(const FetchSalesEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MultiBlocListener(
      listeners: [
        BlocListener<InventoryBloc, InventoryState>(
          listener: (context, invState) {
            if (invState is InventoryLoaded) {
              context.read<PosBloc>().add(
                SyncCartWithInventoryEvent(invState.products),
              );
            }
          },
        ),
        BlocListener<PosBloc, PosState>(
          listener: (context, state) async {
            if (state is SaleAddedSuccess) {
              // Immediately update Inventory stock count across the app
              context.read<InventoryBloc>().add(const FetchProductsEvent());
              // Immediately refresh Reports so analytics and revenue reflect this sale
              context.read<ReportsBloc>().add(const RefreshReportsEvent());

              if (state.generatePdf && state.pdfBytes != null) {
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfPreviewPage(pdfBytes: state.pdfBytes!),
                  ),
                );
              } else {
                if (!context.mounted) return;
                final invoice = state.invoice;
                final fileName = PdfReceiptService.buildReceiptFileName(
                  partyName: invoice?.partyName,
                  date: invoice?.saleDate,
                  billNo: invoice?.invoiceId,
                );

                if (state.pdfBytes != null) {
                  // Auto-save pre-generated receipt PDF to device in background
                  Future.microtask(() async {
                    try {
                      await PdfReceiptService.saveReceiptBytesToDevice(
                        bytes: state.pdfBytes!,
                        fileName: fileName,
                      );
                    } catch (e) {
                      debugPrint('Background PDF receipt auto-save failed: $e');
                    }
                  });
                }

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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sale recorded & invoice saved!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Receipt saved: $fileName',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.white70,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
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
              // Refresh inventory to sync latest stocks if checkout failed due to out of stock
              context.read<InventoryBloc>().add(const FetchProductsEvent());
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
        ),
      ],
      child: BlocBuilder<PosBloc, PosState>(
        builder: (context, state) {
          final isBusy = state is SaleAdding || _isGeneratingPdf;

          return Stack(
            children: [
              PopScope(
                canPop: !isBusy && _searchQuery.isEmpty,
                onPopInvokedWithResult: (didPop, result) {
                  if (didPop) return;
                  if (_searchQuery.isNotEmpty) {
                    _clearSearch();
                  }
                },
                child: Scaffold(
                  appBar: AppBar(
                    title: const Text(
                      'Sales & Billing',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 4,
                        ),
                        child: SizedBox(
                          width: 74,
                          height: 36,
                          child: AppGradientButton(
                            onPressed: isBusy
                                ? null
                                : () => Navigator.push(
                                    context,
                                    DueManagementPage.route(),
                                  ),
                            label: 'Due',
                            height: 36,
                            borderRadius: 8,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 8,
                        ),
                        child: SizedBox(
                          width: 80,
                          height: 36,
                          child: AppGradientButton(
                            onPressed: isBusy
                                ? null
                                : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ReturnsPage(),
                                    ),
                                  ),
                            label: 'Return',
                            height: 36,
                            borderRadius: 8,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  body: AbsorbPointer(
                    absorbing: isBusy,
                    child: Column(
                      children: [
                        // 1. Pinned / Fixed Search Bar at Top
                        Container(
                          color: theme.scaffoldBackgroundColor,
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                          child: PosProductSearchBar(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.trim();
                              });
                            },
                            onClear: _clearSearch,
                          ),
                        ),

                        // 2. Full-Screen Search Results (when searching) OR Cart & Checkout (when idle)
                        // Uses Stack to keep Cart & Checkout mounted so scroll position is preserved!
                        Expanded(
                          child: Stack(
                            children: [
                              // Base Cart & Checkout View (maintains scroll position)
                              RefreshIndicator(
                                onRefresh: () async {
                                  context.read<InventoryBloc>().add(
                                    const FetchProductsEvent(),
                                  );
                                  await Future.delayed(
                                    const Duration(milliseconds: 400),
                                  );
                                },
                                child: SingleChildScrollView(
                                  controller: _scrollController,
                                  key: const PageStorageKey(
                                    'pos_main_scroll_view',
                                  ),
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    6,
                                    16,
                                    24,
                                  ),
                                  child: const Column(
                                    children: [
                                      // Sales Cart Component (Items Only)
                                      PosCartCard(),

                                      SizedBox(height: 16),

                                      // Customer & Checkout Section
                                      PosCheckoutSection(),
                                    ],
                                  ),
                                ),
                              ),

                              // Full-Screen Search Overlay (appears only while searching)
                              if (_searchQuery.isNotEmpty)
                                Positioned.fill(
                                  child: Container(
                                    color: theme.scaffoldBackgroundColor,
                                    child: PosProductSearchResults(
                                      searchQuery: _searchQuery,
                                      onProductSelected: (selectedBatch) {
                                        final parentDocId =
                                            selectedBatch.id.contains('/')
                                            ? selectedBatch.id.split('/')[0]
                                            : selectedBatch.id;
                                        final batchId =
                                            selectedBatch.id.contains('/')
                                            ? selectedBatch.id.split('/')[1]
                                            : '';

                                        final posState = context
                                            .read<PosBloc>()
                                            .state;
                                        final currentCart =
                                            posState is PosLoaded
                                            ? posState.cartItems
                                            : const <CartItem>[];
                                        final isAlreadyInCart = currentCart.any(
                                          (item) =>
                                              item.productId == parentDocId &&
                                              item.batchId == batchId,
                                        );

                                        if (isAlreadyInCart) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).clearSnackBars();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.info_outline_rounded,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      selectedBatch
                                                              .partNo
                                                              .isNotEmpty
                                                          ? '${selectedBatch.itemName} (PN: ${selectedBatch.partNo}) is already in the cart!'
                                                          : '${selectedBatch.itemName} is already in the cart!',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: const Color(
                                                0xFFD97706,
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              duration: const Duration(
                                                seconds: 2,
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        context.read<PosBloc>().add(
                                          AddToCartEvent(
                                            productId: parentDocId,
                                            batchId: batchId,
                                            itemName: selectedBatch.itemName,
                                            partNo: selectedBatch.partNo,
                                            costCode: selectedBatch.costCode,
                                            availableStock:
                                                selectedBatch.stockCount,
                                          ),
                                        );

                                        _clearSearch();
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
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
      ),
    );
  }
}
