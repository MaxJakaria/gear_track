import 'package:flutter/material.dart';

/// Modal dialog for manually setting item quantity with keyboard in POS cart
class PosQuantityEditDialog extends StatefulWidget {
  final String itemName;
  final int initialQuantity;
  final int availableStock;
  final ValueChanged<int> onQuantityChanged;

  const PosQuantityEditDialog({
    super.key,
    required this.itemName,
    required this.initialQuantity,
    required this.availableStock,
    required this.onQuantityChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required String itemName,
    required int initialQuantity,
    required int availableStock,
    required ValueChanged<int> onQuantityChanged,
  }) {
    return showDialog(
      context: context,
      builder: (_) => PosQuantityEditDialog(
        itemName: itemName,
        initialQuantity: initialQuantity,
        availableStock: availableStock,
        onQuantityChanged: onQuantityChanged,
      ),
    );
  }

  @override
  State<PosQuantityEditDialog> createState() => _PosQuantityEditDialogState();
}

class _PosQuantityEditDialogState extends State<PosQuantityEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.initialQuantity}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final qty = int.tryParse(_controller.text.trim());
    final maxAllowed =
        widget.availableStock > 0 ? widget.availableStock : 999999;
    if (qty != null && qty > 0) {
      final capped = qty > maxAllowed ? maxAllowed : qty;
      widget.onQuantityChanged(capped);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Set Quantity',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.itemName,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantity',
              isDense: true,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
