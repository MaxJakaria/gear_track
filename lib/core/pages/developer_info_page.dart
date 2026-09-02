import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DeveloperInfoPage extends StatelessWidget {
  const DeveloperInfoPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const DeveloperInfoPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const accentColor = Color(0xFF6366F1);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Developer Info',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          children: [
            // Top Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(
                      alpha: isDark ? 0.25 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'LEAD SOFTWARE ENGINEER',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Developer Name
            Text(
              'Jakaria Hosen',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),

            Text(
              'Mobile Application Architect & Full-Stack Engineer',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Email with Copy Feature
            _buildInteractiveEmailRow(
              context: context,
              email: 'jakaria.cse.pust@gmail.com',
              isDark: isDark,
            ),
            const Divider(height: 24),

            // Technical Specs
            _buildDetailRow(
              icon: Icons.layers_rounded,
              label: 'Architecture',
              value: 'Clean Architecture (Layered)',
              color: const Color(0xFF4F46E5),
              isDark: isDark,
            ),
            const Divider(height: 24),

            _buildDetailRow(
              icon: Icons.bolt_rounded,
              label: 'State Engine',
              value: 'BLoC (Reactive Event Streams)',
              color: const Color(0xFFF59E0B),
              isDark: isDark,
            ),
            const Divider(height: 24),

            _buildDetailRow(
              icon: Icons.cloud_outlined,
              label: 'Cloud Backend',
              value: 'Google Cloud Firestore',
              color: const Color(0xFF06B6D4),
              isDark: isDark,
            ),
            const Divider(height: 24),

            _buildDetailRow(
              icon: Icons.flutter_dash_rounded,
              label: 'Framework',
              value: 'Flutter 3.x • Dart 3.x',
              color: const Color(0xFF8B5CF6),
              isDark: isDark,
            ),
            const SizedBox(height: 32),

            // Subtle Footer
            Center(
              child: Text(
                'Built with Passion & Clean Code',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveEmailRow({
    required BuildContext context,
    required String email,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(
                alpha: isDark ? 0.2 : 0.1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.email_rounded,
              size: 18,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contact Email',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                email,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.copy_rounded,
              size: 18,
              color: isDark ? const Color(0xFF818CF8) : const Color(0xFF6366F1),
            ),
            tooltip: 'Copy Email',
            splashRadius: 20,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: email));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Email copied to clipboard!'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
