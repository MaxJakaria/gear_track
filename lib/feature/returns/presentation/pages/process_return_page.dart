import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/domain/usecases/get_shop_settings.dart';
import 'package:gear_track/core/entities/shop_settings.dart';
import 'package:gear_track/core/utils/currency_formatter.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:gear_track/feature/point_of_sale/presentation/bloc/pos_bloc.dart';
import 'package:gear_track/feature/point_of_sale/presentation/pages/pdf_preview_page.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';
import 'package:gear_track/feature/reports/presentation/bloc/reports_bloc.dart';
import 'package:gear_track/feature/returns/domain/entities/return_entity.dart';
import 'package:gear_track/feature/returns/presentation/bloc/return_bloc.dart';
import 'package:gear_track/feature/returns/presentation/bloc/return_event.dart';
import 'package:gear_track/feature/returns/presentation/bloc/return_state.dart';
import 'package:gear_track/feature/returns/presentation/widgets/return_item_tile.dart';
import 'package:gear_track/feature/returns/presentation/widgets/return_summary_card.dart';
import 'package:gear_track/feature/returns/utils/pdf_return_voucher_service.dart';
import 'package:gear_track/init_dependencies.dart';

class ProcessReturnPage extends StatefulWidget {
  final InvoiceEntity invoice;

  const ProcessReturnPage({
    super.key,
    required this.invoice,
  });

  @override
  State<ProcessReturnPage> createState() => _ProcessReturnPageState();
}

class _ProcessReturnPageState extends State<ProcessReturnPage> {
  final Map<int, int> _selectedQuantities = {};
  final Map<int, bool> _restockMap = {};
  final Map<int, String> _reasonMap = {};
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize defaults
    for (int i = 0; i < widget.invoice.items.length; i++) {
      _selectedQuantities[i] = 0;
      _restockMap[i] = true;
      _reasonMap[i] = ReturnItemTile.returnReasons.first;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  int get _totalReturnQuantity {
    return _selectedQuantities.values.fold(0, (sum, q) => sum + q);
  }

  double get _totalRefundAmount {
    double total = 0.0;
    for (int i = 0; i < widget.invoice.items.length; i++) {
      final qty = _selectedQuantities[i] ?? 0;
      if (qty > 0) {
        total += qty * widget.invoice.items[i].sellPrice;
      }
    }
    return total;
  }

  int get _restockedCount {
    int count = 0;
    for (int i = 0; i < widget.invoice.items.length; i++) {
      final qty = _selectedQuantities[i] ?? 0;
      if (qty > 0 && (_restockMap[i] ?? true)) {
        count += qty;
      }
    }
    return count;
  }

  int get _nonRestockedCount {
    int count = 0;
    for (int i = 0; i < widget.invoice.items.length; i++) {
      final qty = _selectedQuantities[i] ?? 0;
      if (qty > 0 && !(_restockMap[i] ?? true)) {
        count += qty;
      }
    }
    return count;
  }

  void _confirmAndProcessReturn() {
    if (_totalReturnQuantity <= 0) return;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.assignment_return_rounded, color: Color(0xFFE11D48)),
            SizedBox(width: 8),
            Text('Confirm Sales Return', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'Are you sure you want to process return of $_totalReturnQuantity items and refund ${_totalRefundAmount.toCurrency()} to the customer?\n\n'
          '• $_restockedCount items will be restocked to inventory\n'
          '• $_nonRestockedCount items will be marked as damaged/unsellable',
          style: const TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _submitReturn();
            },
            child: const Text('Confirm Return'),
          ),
        ],
      ),
    );
  }

  void _submitReturn() {
    final List<ReturnItemEntity> returnItems = [];

    for (int i = 0; i < widget.invoice.items.length; i++) {
      final qty = _selectedQuantities[i] ?? 0;
      if (qty > 0) {
        final item = widget.invoice.items[i];
        returnItems.add(
          ReturnItemEntity(
            productId: item.productId,
            batchId: item.batchId,
            itemName: item.itemName,
            partNo: item.partNo,
            quantity: qty,
            sellPrice: item.sellPrice,
            costCode: item.costCode,
            restock: _restockMap[i] ?? true,
            reason: _reasonMap[i] ?? 'Customer Return',
          ),
        );
      }
    }

    final returnId = 'RET-${DateTime.now().millisecondsSinceEpoch}';
    final returnRecord = ReturnEntity(
      returnId: returnId,
      invoiceId: widget.invoice.invoiceId,
      returnDate: DateTime.now(),
      totalRefundAmount: _totalRefundAmount,
      totalQuantity: _totalReturnQuantity,
      reason: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : 'Sales Return & Refund',
      items: returnItems,
      shopName: widget.invoice.shopName,
    );

    context.read<ReturnBloc>().add(ProcessReturnEvent(returnRecord));
  }

  Future<void> _showVoucherPdf(ReturnEntity returnRecord) async {
    ShopSettings shopSettings = const ShopSettings();
    try {
      final getShopSettings = serviceLocator<GetShopSettings>();
      final result = await getShopSettings();
      result.fold((_) {}, (settings) => shopSettings = settings);
    } catch (_) {}

    try {
      final doc = await PdfReturnVoucherService.generateReturnVoucher(
        returnRecord: returnRecord,
        shopSettings: shopSettings,
      );
      final bytes = await doc.save();

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfPreviewPage(pdfBytes: bytes),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to preview voucher: $e'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<ReturnBloc, ReturnState>(
      listener: (context, state) async {
        if (state is ReturnProcessedSuccess) {
          // Immediately update products, sales, and reports across the app
          context.read<InventoryBloc>().add(const FetchProductsEvent());
          context.read<PosBloc>().add(const FetchSalesEvent());
          context.read<ReportsBloc>().add(const FetchReportsEvent());

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Return processed successfully! Refund: ${state.returnRecord.totalRefundAmount.toCurrency()}',
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );

          // Prompt voucher preview
          await _showVoucherPdf(state.returnRecord);

          if (!context.mounted) return;
          Navigator.pop(context, true);
        } else if (state is ReturnFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: const Color(0xFFD32F2F),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final isBusy = state is ReturnLoading;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Process Sales Return',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Invoice Meta Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'INVOICE: ${widget.invoice.invoiceId}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                color: isDark
                                    ? const Color(0xFF818CF8)
                                    : const Color(0xFF4F46E5),
                              ),
                            ),
                            Text(
                              '📅 ${widget.invoice.formattedDate}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Original Total: ${widget.invoice.totalAmount.toCurrency()}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            if (widget.invoice.hasReturns)
                              Text(
                                'Prev. Refunded: ${widget.invoice.returnedAmount.toCurrency()}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'SELECT ITEMS TO RETURN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // List of items
                  ...List.generate(widget.invoice.items.length, (index) {
                    final item = widget.invoice.items[index];
                    return ReturnItemTile(
                      item: item,
                      selectedQuantity: _selectedQuantities[index] ?? 0,
                      restock: _restockMap[index] ?? true,
                      reason: _reasonMap[index] ?? ReturnItemTile.returnReasons.first,
                      onQuantityChanged: (newQty) {
                        setState(() {
                          _selectedQuantities[index] = newQty;
                        });
                      },
                      onRestockChanged: (val) {
                        setState(() {
                          _restockMap[index] = val;
                        });
                      },
                      onReasonChanged: (reason) {
                        setState(() {
                          _reasonMap[index] = reason;
                        });
                      },
                    );
                  }),

                  const SizedBox(height: 8),

                  // Overall Notes field
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Return Notes / Remarks (Optional)',
                      hintText: 'e.g. Customer provided receipt, minor packaging tear',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 16),

                  // Summary Card
                  ReturnSummaryCard(
                    totalReturnQuantity: _totalReturnQuantity,
                    totalRefundAmount: _totalRefundAmount,
                    restockedCount: _restockedCount,
                    nonRestockedCount: _nonRestockedCount,
                    isProcessing: isBusy,
                    onConfirmReturn: _confirmAndProcessReturn,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
