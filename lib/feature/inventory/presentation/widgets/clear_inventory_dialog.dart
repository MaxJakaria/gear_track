import 'package:flutter/material.dart';

/// Confirmation dialog for clearing all products and batches
class ClearInventoryDialog extends StatelessWidget {
  const ClearInventoryDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => const ClearInventoryDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.delete_forever_rounded, color: Color(0xFFD32F2F)),
          SizedBox(width: 8),
          Text('Delete All Products?'),
        ],
      ),
      content: const Text(
        'Are you sure you want to delete all products and batches? This cannot be undone.',
        style: TextStyle(height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFD32F2F),
          ),
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.delete_forever_rounded, size: 18),
          label: const Text('Delete All'),
        ),
      ],
    );
  }
}
