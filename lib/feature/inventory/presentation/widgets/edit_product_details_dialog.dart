import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/theme/app_colors.dart';
import 'package:gear_track/core/widgets/app_gradient_button.dart';
import 'package:gear_track/feature/inventory/domain/entities/grouped_product.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';

class EditProductDetailsDialog extends StatefulWidget {
  final GroupedProduct groupedProduct;

  const EditProductDetailsDialog({super.key, required this.groupedProduct});

  static Future<void> show(
    BuildContext context, {
    required GroupedProduct groupedProduct,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          EditProductDetailsDialog(groupedProduct: groupedProduct),
    );
  }

  @override
  State<EditProductDetailsDialog> createState() =>
      _EditProductDetailsDialogState();
}

class _EditProductDetailsDialogState extends State<EditProductDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _modelController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.groupedProduct.itemName,
    );
    _modelController = TextEditingController(text: widget.groupedProduct.model);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _showFeedback(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final trimmedName = _nameController.text.trim();
    final trimmedModel = _modelController.text.trim();

    if (trimmedName == widget.groupedProduct.itemName.trim() &&
        trimmedModel == widget.groupedProduct.model.trim()) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isLoading = true);

    final completer = Completer<void>();
    context.read<InventoryBloc>().add(
          UpdateGroupedProductDetailsEvent(
            groupedProduct: widget.groupedProduct,
            newItemName: trimmedName,
            newModel: trimmedModel,
            completer: completer,
          ),
        );

    try {
      await completer.future;
      if (mounted) {
        Navigator.of(context).pop();
        _showFeedback('Product details updated successfully!', isError: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showFeedback('Failed to update: $e', isError: true);
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color primaryColor,
    String? Function(String?)? validator,
  }) {
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    return TextFormField(
      controller: controller,
      enabled: !_isLoading,
      textCapitalization: TextCapitalization.words,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.primaryButton(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      elevation: 12,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Edit Product Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (!_isLoading)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        splashRadius: 18,
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nameController,
                  label: 'Product Name',
                  hint: 'Enter product name',
                  icon: Icons.inventory_2_outlined,
                  isDark: isDark,
                  primaryColor: primaryColor,
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Product name cannot be empty'
                      : null,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _modelController,
                  label: 'Model (Optional)',
                  hint: 'e.g. Pro, V2, Standard',
                  icon: Icons.label_outline_rounded,
                  isDark: isDark,
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFCBD5E1),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppGradientButton(
                        onPressed: _isLoading ? null : _handleSave,
                        label: 'Save',
                        icon: Icons.check_rounded,
                        isLoading: _isLoading,
                        height: 44,
                        borderRadius: 10,
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
  }
}
