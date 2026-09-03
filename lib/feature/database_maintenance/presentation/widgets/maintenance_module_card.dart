import 'package:flutter/material.dart';

/// Ultra-minimal, single-row maintenance item for grouped settings layout
class MaintenanceModuleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String actionLabel;
  final bool isProcessing;
  final VoidCallback onAction;
  final bool showDivider;

  const MaintenanceModuleCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.isProcessing,
    required this.onAction,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // Icon Badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.16 : 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(child: Icon(icon, size: 18, color: iconColor)),
              ),
              const SizedBox(width: 11),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.25,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Compact Action Button
              InkWell(
                onTap: isProcessing ? null : onAction,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4.5,
                  ),
                  decoration: BoxDecoration(
                    color: isProcessing
                        ? (isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFE2E8F0))
                        : iconColor.withValues(alpha: isDark ? 0.16 : 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isProcessing
                      ? SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.8,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        )
                      : Text(
                          actionLabel,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                            color: iconColor,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 58,
            endIndent: 14,
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          ),
      ],
    );
  }
}
