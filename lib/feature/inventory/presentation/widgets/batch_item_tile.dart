import 'package:flutter/material.dart';
import 'package:gear_track/feature/inventory/domain/entities/product.dart';

class BatchItemTile extends StatelessWidget {
  final Product batch;
  final int index;
  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BatchItemTile({
    super.key,
    required this.batch,
    required this.index,
    this.isDeleting = false,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatDate(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOut = batch.stockCount <= 0;
    final isLow = batch.stockCount > 0 && batch.stockCount <= 5;

    final statusColor = isOut
        ? theme.colorScheme.error
        : isLow
        ? const Color(0xFFE65100)
        : const Color(0xFF00875A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainer
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outline.withValues(alpha: 0.15)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Compact Batch # Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 2. Batch Meta (Part No, Cost Code & Date)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'P/N: ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        batch.partNo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFF818CF8)
                              : const Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Cost: ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        batch.costCode.isEmpty ? 'N/A' : batch.costCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      ' • ${_formatDate(batch.entryDate)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.75,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. Intuitive Stock Ratio Pill (Available / Initial)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${batch.stockCount}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
                Text(
                  ' / ${batch.initialQuantity}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.75,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // 4. Sleek Inline Action Buttons (Edit & Delete)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edit Button
              InkWell(
                onTap: isDeleting ? null : onEdit,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Delete Button
              InkWell(
                onTap: isDeleting ? null : onDelete,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: isDeleting
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.error,
                          ),
                        )
                      : Icon(
                          Icons.delete_outline_rounded,
                          size: 14,
                          color: theme.colorScheme.error,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
