import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/widgets/app_gradient_button.dart';
import 'package:gear_track/core/widgets/custom_date_picker_dialog.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';

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

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
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

  Future<void> _submit() async {
    if (_isLoading) return;
    if (_formKey.currentState?.validate() ?? false) {
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
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Part No required'
                            : null,
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _costCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Cost Code',
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
                  onPressed: _isLoading ? null : _submit,
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
