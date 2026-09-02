import 'package:flutter/material.dart';
import 'package:gear_track/core/widgets/custom_confirm_delete_dialog.dart';

/// Confirmation dialog for clearing all products and batches
class ClearInventoryDialog {
  static Future<bool?> show(BuildContext context) {
    return CustomConfirmDeleteDialog.show(
      context,
      title: 'Delete All Products?',
      description:
          'Are you sure you want to delete all products and batches? This action cannot be undone.',
      confirmLabel: 'Delete All',
      icon: Icons.delete_forever_rounded,
    );
  }
}
