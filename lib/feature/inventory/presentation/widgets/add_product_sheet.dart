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

class AddProductSheet extends StatefulWidget {
  const AddProductSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddProductSheet(),
    );
  }

  @override
  State<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<AddProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _partNoController = TextEditingController();
  final _modelController = TextEditingController();
  final _costCodeController = TextEditingController();
  final _stockCountController = TextEditingController(text: '0');

  CostCodeMapping _mapping = const CostCodeMapping(charToDigit: {});
  String _decodedCost = '';

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMapping();
    _costCodeController.addListener(_updateDecodedCost);
    _partNoController.addListener(_onFieldChanged);
    _itemNameController.addListener(_onFieldChanged);
    _modelController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
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
    _partNoController.removeListener(_onFieldChanged);
    _itemNameController.removeListener(_onFieldChanged);
    _modelController.removeListener(_onFieldChanged);
    _itemNameController.dispose();
    _partNoController.dispose();
    _modelController.dispose();
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

  GroupedProduct? _findMatchingProduct(List<GroupedProduct> list) {
    final clean = _partNoController.text.trim().toLowerCase();
    if (clean.isEmpty) return null;
    for (final p in list) {
      if (p.partNo.trim().toLowerCase() == clean ||
          p.batches.any((b) => b.partNo.trim().toLowerCase() == clean)) {
        return p;
      }
    }
    return null;
  }

  Future<void> _submit(GroupedProduct? matched, bool hasConflict) async {
    if (_isLoading) return;
    if (_formKey.currentState?.validate() ?? false) {
      if (matched != null && hasConflict) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot add product: Part Number "${_partNoController.text.trim()}" is already assigned to "${matched.itemName}" (${matched.model}).',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (matched != null && !hasConflict) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Add to Existing Product?'),
            content: Text(
              'A product with Part Number "${matched.partNo}" already exists:\n\n'
              '• Item: ${matched.itemName}\n'
              '• Model: ${matched.model}\n\n'
              'Submitting will add this stock as a new batch under "${matched.itemName}". Do you want to proceed?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Add Batch'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        if (!mounted) return;
      }

      setState(() => _isLoading = true);
      final stock = int.tryParse(_stockCountController.text.trim()) ?? 0;
      final completer = Completer<void>();

      context.read<InventoryBloc>().add(
        AddProductEvent(
          itemName: _itemNameController.text.trim(),
          partNo: _partNoController.text.trim(),
          model: _modelController.text.trim(),
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
              content: Text('Product added successfully!'),
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
    final matched = _findMatchingProduct(existingGrouped);

    final enteredName = _itemNameController.text.trim();
    final enteredModel = _modelController.text.trim();

    bool hasConflict = false;
    bool isSameProduct = false;

    if (matched != null) {
      final matchesName = enteredName.isEmpty ||
          enteredName.toLowerCase() == matched.itemName.toLowerCase();
      final matchesModel = enteredModel.isEmpty ||
          enteredModel.toLowerCase() == matched.model.toLowerCase();

      if (matchesName && matchesModel) {
        isSameProduct = true;
      } else {
        hasConflict = true;
      }
    }

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
                        'Add New Product',
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _itemNameController,
                    decoration: const InputDecoration(
                      labelText: 'Item Name',
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Item name is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _partNoController,
                          decoration: const InputDecoration(
                            labelText: 'Part Number',
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Part No required';
                            }
                            if (matched != null && hasConflict) {
                              return 'Used by "${matched.itemName}"';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _modelController,
                          decoration: const InputDecoration(
                            labelText: 'Model',
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Model required'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  if (matched != null) ...[
                    const SizedBox(height: 10),
                    if (hasConflict)
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
                                'Part Number already belongs to "${matched.itemName}" (${matched.model}). Part numbers must be unique across different products.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (enteredName.isEmpty && enteredModel.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(
                            alpha: isDark ? 0.2 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF6366F1).withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Color(0xFF6366F1),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Matches: "${matched.itemName}" (${matched.model})',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? const Color(0xFFA5B4FC)
                                      : const Color(0xFF4338CA),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () {
                                _itemNameController.text = matched.itemName;
                                _modelController.text = matched.model;
                              },
                              child: const Text('Autofill'),
                            ),
                          ],
                        ),
                      )
                    else if (isSameProduct)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(
                            alpha: isDark ? 0.2 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 18,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Existing product. Submitting will add this stock as a new batch under "${matched.itemName}".',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? Colors.amber.shade200
                                      : Colors.amber.shade900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 12),
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
                              ? 'Cost Code required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _stockCountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Stock Count',
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
                    onPressed: _isLoading
                        ? null
                        : () => _submit(matched, hasConflict),
                    isLoading: _isLoading,
                    label: 'Save Product',
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
