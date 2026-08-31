import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/widgets/app_gradient_button.dart';
import 'package:gear_track/core/widgets/custom_date_picker_dialog.dart';
import 'package:gear_track/feature/inventory/domain/entities/product.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';

class EditProductSheet extends StatefulWidget {
  final Product product;

  const EditProductSheet({super.key, required this.product});

  static Future<void> show(BuildContext context, Product product) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProductSheet(product: product),
    );
  }

  @override
  State<EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends State<EditProductSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _partNoController;
  late final TextEditingController _costCodeController;
  late final TextEditingController _stockCountController;
  late DateTime _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _partNoController = TextEditingController(text: widget.product.partNo);
    _costCodeController = TextEditingController(text: widget.product.costCode);
    _stockCountController = TextEditingController(
      text: widget.product.stockCount.toString(),
    );
    _selectedDate = widget.product.entryDate;
  }

  @override
  void dispose() {
    _partNoController.dispose();
    _costCodeController.dispose();
    _stockCountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await CustomDatePickerDialog.show(
      context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      final stock = int.tryParse(_stockCountController.text.trim()) ?? 0;
      final updatedProduct = Product(
        id: widget.product.id,
        entryDate: _selectedDate,
        partNo: _partNoController.text.trim(),
        itemName: widget.product.itemName,
        model: widget.product.model,
        costCode: _costCodeController.text.trim(),
        initialQuantity: widget.product.initialQuantity,
        stockCount: stock,
      );

      final completer = Completer<void>();
      context.read<InventoryBloc>().add(
        UpdateProductEvent(updatedProduct, completer: completer),
      );

      try {
        await completer.future;
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: bottomPadding + 20,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Batch Entry',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Read-only Product Context Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.itemName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.product.model.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Model: ${widget.product.model}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Editable Part Number Input Field (Matching Quick Add Stock Sheet)
                TextFormField(
                  controller: _partNoController,
                  decoration: const InputDecoration(
                    labelText: 'Part Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Part No is required'
                      : null,
                ),
                const SizedBox(height: 12),

                // Dynamic Input Fields (Cost Code & Stock Count)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _costCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Cost Code',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Cost code required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stockCountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity / Count',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Required';
                          }
                          final parsed = int.tryParse(val.trim());
                          if (parsed == null || parsed < 0) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Entry Date Picker
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(4),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Entry Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(_formatDate(_selectedDate)),
                  ),
                ),
                const SizedBox(height: 24),

                AppGradientButton(
                  onPressed: _isLoading ? null : _submit,
                  isLoading: _isLoading,
                  label: 'Update Batch',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
