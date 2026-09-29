import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/theme/app_colors.dart';
import 'package:gear_track/core/utils/currency_formatter.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';
import 'package:gear_track/feature/reports/presentation/bloc/reports_bloc.dart';
import 'package:gear_track/feature/returns/domain/entities/return_entity.dart';
import 'package:gear_track/feature/returns/presentation/bloc/return_bloc.dart';
import 'package:gear_track/feature/returns/presentation/bloc/return_event.dart';
import 'package:gear_track/feature/returns/presentation/bloc/return_state.dart';
import 'package:gear_track/feature/due_management/presentation/bloc/due_bloc.dart';
import 'package:gear_track/feature/due_management/presentation/bloc/due_event.dart';
import 'package:gear_track/feature/returns/presentation/widgets/return_item_tile.dart';
import 'package:gear_track/feature/returns/presentation/widgets/return_summary_card.dart';

/// Minimalist, high-end return processing page matching GearTrack's luxury UI
class ProcessReturnPage extends StatefulWidget {
  final InvoiceEntity invoice;
  final int? initialItemIndex;

  const ProcessReturnPage({
    super.key,
    required this.invoice,
    this.initialItemIndex,
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
    for (int i = 0; i < widget.invoice.items.length; i++) {
      final isTarget =
          widget.initialItemIndex != null && widget.initialItemIndex == i;
      final returnable = widget.invoice.items[i].returnableQuantity;
      _selectedQuantities[i] = isTarget && returnable > 0 ? 1 : 0;
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

  bool get _allReturnableSelected {
    bool hasAny = false;
    for (int i = 0; i < widget.invoice.items.length; i++) {
      final returnable = widget.invoice.items[i].returnableQuantity;
      if (returnable > 0) {
        hasAny = true;
        if ((_selectedQuantities[i] ?? 0) < returnable) return false;
      }
    }
    return hasAny;
  }

  void _selectAllAvailable() {
    setState(() {
      for (int i = 0; i < widget.invoice.items.length; i++) {
        _selectedQuantities[i] = widget.invoice.items[i].returnableQuantity;
      }
    });
  }

  void _clearAllSelections() {
    setState(() {
      for (int i = 0; i < widget.invoice.items.length; i++) {
        _selectedQuantities[i] = 0;
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<ReturnBloc, ReturnState>(
      listener: (context, state) async {
        if (state is ReturnProcessedSuccess) {
          // 1. Immediately refresh inventory to update restocked counts
          context.read<InventoryBloc>().add(const FetchProductsEvent());
          // 2. Immediately refresh reports so refunds and net figures update
          context.read<ReportsBloc>().add(const RefreshReportsEvent());
          // 3. Refresh returns history
          context.read<ReturnBloc>().add(const FetchReturnsEvent());
          // 4. Refresh due management list
          context.read<DueBloc>().add(const FetchDueInvoicesEvent());

          final existingDue = widget.invoice.dueAmount;
          final returnVal = state.returnRecord.totalRefundAmount;
          final dueDeduction = returnVal > existingDue
              ? existingDue
              : returnVal;
          final cashRefund = (returnVal - dueDeduction).clamp(
            0.0,
            double.infinity,
          );

          final String successMsg = existingDue > 0.001
              ? 'Return processed! Adjusted from due: ${dueDeduction.toCurrency()}${cashRefund > 0.001 ? ', Cash refund: ${cashRefund.toCurrency()}' : ''}'
              : 'Return processed! Refund: ${returnVal.toCurrency()}';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(successMsg)),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 3),
            ),
          );

          if (!context.mounted) return;
          Navigator.pop(context, true);
        } else if (state is ReturnFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: const Color(0xFFD32F2F),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final isBusy = state is ReturnLoading;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Process Return',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          bottomNavigationBar: ReturnSummaryCard(
            totalReturnQuantity: _totalReturnQuantity,
            totalRefundAmount: _totalRefundAmount,
            restockedCount: _restockedCount,
            nonRestockedCount: _nonRestockedCount,
            isProcessing: isBusy,
            onConfirmReturn: _submitReturn,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Enhanced Invoice Meta Card with Payment Status
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Invoice ID, Date, and PAID/DUE Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.invoice.invoiceId,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'monospace',
                                    color: isDark
                                        ? AppColors.primaryButtonDark
                                        : AppColors.primaryButtonLight,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.invoice.formattedDate,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: widget.invoice.hasDue
                                    ? const Color(
                                        0xFFEF4444,
                                      ).withValues(alpha: 0.12)
                                    : const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.invoice.hasDue
                                    ? 'DUE: ${widget.invoice.dueAmount.toCurrency()}'
                                    : 'PAID',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: widget.invoice.hasDue
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (widget.invoice.partyName.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Customer: ${widget.invoice.partyName}'
                            '${widget.invoice.partyAddress.isNotEmpty ? ' (${widget.invoice.partyAddress})' : ''}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ],

                        const SizedBox(height: 8),

                        // Row 3: Financial Summary (Total, Paid, Due)
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            Text(
                              'Total: ${widget.invoice.totalAmount.toCurrency()}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              'Paid: ${widget.invoice.paidAmount.toCurrency()}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF059669),
                              ),
                            ),
                            if (widget.invoice.hasDue)
                              Text(
                                'Due: ${widget.invoice.dueAmount.toCurrency()}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            if (widget.invoice.hasReturns)
                              Text(
                                'Prev. Refunded: ${widget.invoice.returnedAmount.toCurrency()}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Dynamic Refund Settlement Preview Box
                  if (_totalReturnQuantity > 0) ...[
                    const SizedBox(height: 10),
                    _buildRefundSettlementPreview(isDark),
                  ],

                  const SizedBox(height: 12),

                  // Section Header & Quick Select Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SELECT ITEMS TO RETURN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: _allReturnableSelected
                            ? _clearAllSelections
                            : _selectAllAvailable,
                        child: Text(
                          _allReturnableSelected ? 'Clear All' : 'Select All',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.primaryButtonDark
                                : AppColors.primaryButtonLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // List of items
                  ...List.generate(widget.invoice.items.length, (index) {
                    final item = widget.invoice.items[index];
                    return ReturnItemTile(
                      item: item,
                      selectedQuantity: _selectedQuantities[index] ?? 0,
                      restock: _restockMap[index] ?? true,
                      reason:
                          _reasonMap[index] ??
                          ReturnItemTile.returnReasons.first,
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

                  // Compact Optional Notes field
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Return Remarks (Optional)',
                      hintText: 'e.g. Receipt verified, customer replacement',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    style: const TextStyle(fontSize: 12.5),
                    maxLines: 1,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRefundSettlementPreview(bool isDark) {
    final existingDue = widget.invoice.dueAmount;
    final returnVal = _totalRefundAmount;
    final dueDeduction = returnVal > existingDue ? existingDue : returnVal;
    final cashRefund = (returnVal - dueDeduction).clamp(0.0, double.infinity);
    final remainingDueAfter = (existingDue - dueDeduction).clamp(
      0.0,
      double.infinity,
    );

    final isDueAdjustment = existingDue > 0.001;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDueAdjustment
            ? (isDark
                  ? const Color(0xFF78350F).withValues(alpha: 0.25)
                  : const Color(0xFFFEF3C7))
            : (isDark
                  ? const Color(0xFF064E3B).withValues(alpha: 0.25)
                  : const Color(0xFFD1FAE5)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDueAdjustment
              ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
              : const Color(0xFF10B981).withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDueAdjustment
                    ? Icons.info_outline_rounded
                    : Icons.check_circle_outline_rounded,
                size: 15,
                color: isDueAdjustment
                    ? const Color(0xFFD97706)
                    : const Color(0xFF059669),
              ),
              const SizedBox(width: 6),
              Text(
                isDueAdjustment
                    ? 'REFUND SETTLEMENT BREAKDOWN'
                    : 'FULL PAID INVOICE REFUND',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                  color: isDueAdjustment
                      ? (isDark
                            ? const Color(0xFFFDE68A)
                            : const Color(0xFF92400E))
                      : (isDark
                            ? const Color(0xFFA7F3D0)
                            : const Color(0xFF065F46)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (isDueAdjustment) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Returned Items Value: ${returnVal.toCurrency()}',
                  style: const TextStyle(fontSize: 11.5),
                ),
                Text(
                  'Deducted from Due: -${dueDeduction.toCurrency()}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remaining Due After: ${remainingDueAfter.toCurrency()}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                Text(
                  'Cash Refund: ${cashRefund.toCurrency()}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: cashRefund > 0.001
                        ? const Color(0xFF10B981)
                        : (isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Customer has fully paid for this invoice. Cash refund: ${returnVal.toCurrency()}',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFFA7F3D0)
                    : const Color(0xFF065F46),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
