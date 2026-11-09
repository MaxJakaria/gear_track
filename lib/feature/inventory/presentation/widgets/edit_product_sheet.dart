import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/domain/usecases/get_cost_code_mapping.dart';
import 'package:gear_track/core/entities/cost_code_mapping.dart';
import 'package:gear_track/core/widgets/app_gradient_button.dart';
import 'package:gear_track/core/widgets/custom_date_picker_dialog.dart';
import 'package:gear_track/feature/inventory/domain/entities/product.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:gear_track/init_dependencies.dart';

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
  late final TextEditingController _qtyController;
  late DateTime _selectedDate;
  bool _isLoading = false;

  late final int _oldInitialQty;
  late final int _oldStockCount;
  int _calculatedStockCount = 0;

  CostCodeMapping _mapping = const CostCodeMapping(charToDigit: {});
  String _decodedCost = '';

  @override
  void initState() {
    super.initState();
    _oldInitialQty = widget.product.initialQuantity;
    _oldStockCount = widget.product.stockCount;
    _calculatedStockCount = _oldStockCount;

    _partNoController = TextEditingController(text: widget.product.partNo);
    _costCodeController = TextEditingController(text: widget.product.costCode);
    _qtyController = TextEditingController(text: _oldInitialQty.toString());
    _selectedDate = widget.product.entryDate;

    _loadMapping();
    _costCodeController.addListener(_updateDecodedCost);
    _qtyController.addListener(_updateCalculatedStock);
  }

  void _updateCalculatedStock() {
    final input = int.tryParse(_qtyController.text.trim());
    if (input != null) {
      final delta = input - _oldInitialQty;
      final newStock = _oldStockCount + delta;
      if (_calculatedStockCount != newStock) {
        setState(() => _calculatedStockCount = newStock);
      }
    }
  }

  Future<void> _loadMapping() async {
    final result = await serviceLocator<GetCostCodeMapping>()();
    result.fold((_) {}, (mapping) {
      if (mounted) {
        setState(() {
          _mapping = mapping;
          _updateDecodedCost();
        });
      }
    });
  }

  void _updateDecodedCost() {
    final input = _costCodeController.text.trim();
    if (input.isEmpty) {
      if (_decodedCost.isNotEmpty) {
        setState(() => _decodedCost = '');
      }
      return;
    }
    final val = _mapping.decode(input);
    final formatted = val % 1 == 0
        ? '৳${val.toInt()}'
        : '৳${val.toStringAsFixed(1)}';
    if (_decodedCost != formatted) {
      setState(() => _decodedCost = formatted);
    }
  }

  @override
  void dispose() {
    _costCodeController.removeListener(_updateDecodedCost);
    _qtyController.removeListener(_updateCalculatedStock);
    _partNoController.dispose();
    _costCodeController.dispose();
    _qtyController.dispose();
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

      final newInput = int.parse(_qtyController.text.trim());
      final delta = newInput - _oldInitialQty;
      final newStockCount = _oldStockCount + delta;

      final updatedProduct = Product(
        id: widget.product.id,
        entryDate: _selectedDate,
        partNo: _partNoController.text.trim(),
        itemName: widget.product.itemName,
        model: widget.product.model,
        costCode: _costCodeController.text.trim(),
        initialQuantity: newInput,
        stockCount: newStockCount,
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
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Container(
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
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
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

                  // Editable Part Number Input Field
                  TextFormField(
                    controller: _partNoController,
                    decoration: const InputDecoration(labelText: 'Part Number'),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Part No is required'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Cost Code Input Field with Live Decoded Preview
                  TextFormField(
                    controller: _costCodeController,
                    decoration: InputDecoration(
                      labelText: 'Cost Code',
                      suffixIcon: _decodedCost.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: UnconstrainedBox(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF6366F1,
                                    ).withValues(alpha: isDark ? 0.25 : 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF6366F1,
                                      ).withValues(alpha: 0.35),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    _decodedCost,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF6366F1),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Cost code required'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Batch Input / Initial Quantity Field
                  TextFormField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Batch Quantity',
                      hintText: 'Enter batch input quantity',
                      prefixIcon: Icon(Icons.add_box_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Quantity is required';
                      }
                      final input = int.tryParse(val.trim());
                      if (input == null) {
                        return 'Please enter a valid number';
                      }
                      final consumed = _oldInitialQty - _oldStockCount;
                      if (input < consumed) {
                        return 'Cannot be less than $consumed ($consumed already sold/used)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Live Present Stock Auto-Calculation Preview Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: isDark ? 0.35 : 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Present Stock (Auto-calculated)',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$_calculatedStockCount units',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _calculatedStockCount < _oldStockCount
                                      ? (isDark
                                          ? Colors.orangeAccent
                                          : Colors.orange.shade800)
                                      : (_calculatedStockCount > _oldStockCount
                                          ? (isDark
                                              ? Colors.greenAccent
                                              : Colors.green.shade800)
                                          : theme.colorScheme.onSurface),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_calculatedStockCount != _oldStockCount)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: (_calculatedStockCount > _oldStockCount
                                      ? Colors.green
                                      : Colors.orange)
                                  .withValues(alpha: isDark ? 0.25 : 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: (_calculatedStockCount > _oldStockCount
                                        ? Colors.green
                                        : Colors.orange)
                                    .withValues(alpha: 0.5),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              (_calculatedStockCount - _oldStockCount) > 0
                                  ? '+${_calculatedStockCount - _oldStockCount}'
                                  : '${_calculatedStockCount - _oldStockCount}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _calculatedStockCount > _oldStockCount
                                    ? (isDark
                                        ? Colors.greenAccent
                                        : Colors.green.shade800)
                                    : (isDark
                                        ? Colors.orangeAccent
                                        : Colors.orange.shade900),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Entry Date Picker
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(4),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Entry Date',
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
      ),
    );
  }
}
