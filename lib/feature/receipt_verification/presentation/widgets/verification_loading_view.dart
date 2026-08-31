import 'package:flutter/material.dart';

class VerificationLoadingView extends StatelessWidget {
  const VerificationLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Glowing Progress Indicator
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                ),
              ),
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
              ),
              const Icon(
                Icons.cloud_sync_rounded,
                size: 22,
                color: Color(0xFF6366F1),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Loading Text
          Text(
            'Verifying Receipt Authenticity',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Querying official GearTrack cloud database...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
