import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/utils/currency_formatter.dart';
import 'package:gear_track/feature/due_management/presentation/bloc/due_bloc.dart';
import 'package:gear_track/feature/due_management/presentation/bloc/due_event.dart';
import 'package:gear_track/feature/due_management/presentation/bloc/due_state.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';

class CollectDueDialog extends StatefulWidget {
  final InvoiceEntity invoice;

  const CollectDueDialog({
    super.key,
    required this.invoice,
  });

  static Future<bool?> show(BuildContext context, InvoiceEntity invoice) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<DueBloc>(),
        child: CollectDueDialog(invoice: invoice),
      ),
    );
  }

  @override
  State<CollectDueDialog> createState() => _CollectDueDialogState();
}

class _CollectDueDialogState extends State<CollectDueDialog> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-fill with the full due amount for maximum convenience
    _amountController.text = widget.invoice.dueAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submitPayment() {
    setState(() => _errorMessage = null);
    final text = _amountController.text.trim();
    final amount = double.tryParse(text);

    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount');
      return;
    }

    if (amount > widget.invoice.dueAmount + 0.01) {
      setState(() {
        _errorMessage =
            'Amount cannot exceed outstanding due (${widget.invoice.dueAmount.toCurrency()})';
      });
      return;
    }

    context.read<DueBloc>().add(
          CollectDuePaymentEvent(
            invoiceId: widget.invoice.invoiceId,
            paymentAmount: amount,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF6366F1);
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return BlocConsumer<DueBloc, DueState>(
      listener: (context, state) {
        if (state is DuePaymentSuccess &&
            state.updatedInvoice.invoiceId == widget.invoice.invoiceId) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment of ${state.collectedAmount.toCurrency()} received successfully!',
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        } else if (state is DueError) {
          setState(() => _errorMessage = state.message);
        }
      },
      builder: (context, state) {
        final isProcessing = state is DuePaymentProcessing &&
            state.invoiceId == widget.invoice.invoiceId;

        return Dialog(
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.payments_rounded,
                            color: Color(0xFFEF4444),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Collect Due Payment',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.invoice.invoiceId,
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
                        IconButton(
                          onPressed: isProcessing ? null : () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Customer & Invoice Summary Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          if (widget.invoice.partyName.isNotEmpty) ...[
                            _buildInfoRow('Customer', widget.invoice.partyName, isDark),
                            const SizedBox(height: 6),
                          ],
                          if (widget.invoice.partyAddress.isNotEmpty) ...[
                            _buildInfoRow('Address', widget.invoice.partyAddress, isDark),
                            const SizedBox(height: 6),
                          ],
                          _buildInfoRow(
                            'Total Bill',
                            widget.invoice.totalAmount.toCurrency(),
                            isDark,
                          ),
                          const SizedBox(height: 6),
                          _buildInfoRow(
                            'Paid So Far',
                            widget.invoice.paidAmount.toCurrency(),
                            isDark,
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Current Outstanding Due',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                widget.invoice.dueAmount.toCurrency(),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Input Field
                    const Text(
                      'Received Amount (৳)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      enabled: !isProcessing,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.currency_pound, size: 20),
                        hintText: 'Enter amount received',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Quick Preset Chips
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          label: Text('Full (${widget.invoice.dueAmount.toCurrency()})'),
                          labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                          backgroundColor: primaryColor.withValues(alpha: 0.1),
                          side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                          onPressed: isProcessing
                              ? null
                              : () {
                                  _amountController.text =
                                      widget.invoice.dueAmount.toStringAsFixed(0);
                                },
                        ),
                        if (widget.invoice.dueAmount >= 200)
                          ActionChip(
                            label: Text(
                              'Half (${(widget.invoice.dueAmount / 2).toStringAsFixed(0)})',
                            ),
                            labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                            backgroundColor: isDark
                                ? const Color(0xFF334155).withValues(alpha: 0.4)
                                : const Color(0xFFE2E8F0),
                            side: BorderSide.none,
                            onPressed: isProcessing
                                ? null
                                : () {
                                    _amountController.text =
                                        (widget.invoice.dueAmount / 2).toStringAsFixed(0);
                                  },
                          ),
                      ],
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isProcessing ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isProcessing ? null : _submitPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: isProcessing
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Confirm Payment',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
