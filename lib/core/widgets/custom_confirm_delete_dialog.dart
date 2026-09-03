import 'package:flutter/material.dart';

/// Single unified confirmation dialog for all delete operations across the app.
class CustomConfirmDeleteDialog extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? contentWidget;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;
  final Color iconColor;

  const CustomConfirmDeleteDialog({
    super.key,
    required this.title,
    this.description,
    this.contentWidget,
    this.confirmLabel = 'Delete',
    this.cancelLabel = 'Cancel',
    this.icon = Icons.delete_outline_rounded,
    this.iconColor = const Color(0xFFDC2626),
  });

  /// Helper static method to show the unified delete dialog.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? description,
    Widget? contentWidget,
    String confirmLabel = 'Delete',
    String cancelLabel = 'Cancel',
    IconData icon = Icons.delete_outline_rounded,
    Color iconColor = const Color(0xFFDC2626),
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => CustomConfirmDeleteDialog(
        title: title,
        description: description,
        contentWidget: contentWidget,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        icon: icon,
        iconColor: iconColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actionsOverflowButtonSpacing: 8,
      actionsOverflowDirection: VerticalDirection.down,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: contentWidget ??
          (description != null
              ? Text(
                  description!,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                )
              : null),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            foregroundColor:
                isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            cancelLabel,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: iconColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => Navigator.pop(context, true),
          icon: Icon(icon, size: 18),
          label: Text(
            confirmLabel,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          ),
        ),
      ],
    );
  }
}
