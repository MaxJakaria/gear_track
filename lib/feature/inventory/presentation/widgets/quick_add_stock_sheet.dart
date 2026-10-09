import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/domain/usecases/get_cost_code_mapping.dart';
import 'package:gear_track/core/entities/cost_code_mapping.dart';
import 'package:gear_track/core/widgets/app_gradient_button.dart';
import 'package:gear_track/core/widgets/custom_date_picker_dialog.dart';
import 'package:gear_track/feature/inventory/domain/entities/grouped_product.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:gear_track/init_dependencies.dart';

class QuickAddStockSheet extends StatefulWidget {
  final GroupedProduct groupedProduct;

  const QuickAddStockSheet({super.key, required this.groupedProduct});

  static Future<void> show(
    BuildContext context,
    GroupedProduct groupedProduct,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickAddStockSheet(groupedProduct: groupedProduct),
    );
  }

  @override
  State<QuickAddStockSheet> createState() => _QuickAddStockSheetState();
}

class _QuickAddStockSheetState extends State<QuickAddStockSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _partNoController;
  late final TextEditingController _costCodeController;
  final _stockCountController = TextEditingController(text: '1');

  CostCodeMapping _mapping = const CostCodeMapping(charToDigit: {});
  String _decodedCost = '';

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _partNoController =
        TextEditingController(text: widget.groupedProduct.partNo);
    _costCodeController =
        TextEditingController(text: widget.groupedProduct.latestCostCode);
    _loadMapping();
    _costCodeController.addListener(_updateDecodedCost);
    _partNoController.addListener(_onPartNoChanged);
  }

  void _onPartNoChanged() {
    if (mounted) setState(() {});
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
    final formatted =
        val % 1 == 0 ? '৳${val.toInt()}' : '৳${val.toStringAsFixed(1)}';
    if (_decodedCost != formatted) {
      setState(() => _decodedCost = formatted);
    }
  }

  @override
  void dispose() {
    _costCodeController.removeListener(_updateDecodedCost);
    _partNoController.removeListener(_onPartNoChanged);
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

  GroupedProduct? _findConflictingProduct(List<GroupedProduct> list) {
    final clean = _partNoController.text.trim().toLowerCase();
    if (clean.isEmpty) return null;
    final currentKey = widget.groupedProduct.groupKey;
    for (final p in list) {
      if (p.groupKey == currentKey) continue;
      if (p.partNo.trim().toLowerCase() == clean ||
          p.batches.any((b) => b.partNo.trim().toLowerCase() == clean)) {
        return p;
      }
    }
    return null;
  }

  Future<void> _submit(GroupedProduct? conflict) async {
    if (_isLoading) return;
    if (_formKey.currentState?.validate() ?? false) {
      if (conflict != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot add batch: Part Number "${_partNoController.text.trim()}" already belongs to "${conflict.itemName}" (${conflict.model}).',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);
      final stock = int.tryParse(_stockCountController.text.trim()) ?? 0;
      final completer = Completer<void>();

      context.read<InventoryBloc>().add(
        AddProductEvent(
          itemName: widget.groupedProduct.itemName,
          partNo: _partNoController.text.trim(),
          model: widget.groupedProduct.model,
          costCode: _costCodeController.text.trim(),
          stockCount: stock,
          entryDate: _selectedDate,
          completer: completer,
        ),
      );

      try {
        await completer.future;
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stock batch added successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
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

    final invState = context.watch<InventoryBloc>().state;
    final List<GroupedProduct> existingGrouped =
        invState is InventoryLoaded ? invState.groupedProducts : const [];
    final conflict = _findConflictingProduct(existingGrouped);

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
                        'Quick Add Stock Batch',
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
                          widget.groupedProduct.itemName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.groupedProduct.model.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Model: ${widget.groupedProduct.model}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mandatory Part Number Input Field
                  TextFormField(
                    controller: _partNoController,
                    decoration: const InputDecoration(
                      labelText: 'Part Number',
                      hintText: 'Enter part number for this batch',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Part No is required';
                      }
                      if (conflict != null) {
                        return 'Used by "${conflict.itemName}"';
                      }
                      return null;
                    },
                  ),
                  if (conflict != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(
                          alpha: isDark ? 0.2 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 20,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Part Number already belongs to "${conflict.itemName}" (${conflict.model}). Part numbers cannot be reused across different products.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Dynamic Input Fields (Cost Code with Live Decoded Preview & Stock Count)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
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
                                          color: const Color(0xFF6366F1)
                                              .withValues(
                                            alpha: isDark ? 0.25 : 0.12,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: const Color(0xFF6366F1)
                                                .withValues(alpha: 0.35),
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
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _stockCountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Quantity / Count',
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Required';
                            }
                            final parsed = int.tryParse(val.trim());
                            if (parsed == null || parsed <= 0) {
                              return 'Enter > 0';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

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
                    onPressed: _isLoading ? null : () => _submit(conflict),
                    isLoading: _isLoading,
                    label: 'Add Stock Batch',
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
