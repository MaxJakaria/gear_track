import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const AboutPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About GearTrack',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // App Title Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GearTrack Pro',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'v1.0.0 Pro',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Industrial Inventory, Point of Sale & Supply Chain Suite',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'An enterprise ERP platform engineered for mechanical hardware suppliers, automotive distributors, and retail industrial outlets.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Features List (Flat)
            _buildFeatureRow(
              icon: Icons.sync_rounded,
              title: 'Real-Time Inventory Sync',
              subtitle: 'Live multi-device stock tracking and low-stock alerts.',
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            _buildFeatureRow(
              icon: Icons.vpn_key_rounded,
              title: 'Secret Cost Code Privacy',
              subtitle: 'Wholesale price obfuscation on physical price tags.',
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            _buildFeatureRow(
              icon: Icons.shopping_cart_rounded,
              title: 'Point of Sale & Invoicing',
              subtitle: 'Instant cashier checkout with live stock validation.',
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            _buildFeatureRow(
              icon: Icons.qr_code_scanner_rounded,
              title: 'Receipt Verification',
              subtitle: 'Digital invoice authentication & QR code lookup.',
              isDark: isDark,
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Specifications (Flat)
            _buildSpecRow('Version', '1.0.0 Pro (Build 2026.1)', isDark),
            const SizedBox(height: 10),
            _buildSpecRow('Framework', 'Flutter 3.x • Dart 3.x', isDark),
            const SizedBox(height: 10),
            _buildSpecRow('Cloud Database', 'Google Cloud Firestore', isDark),
            const SizedBox(height: 10),
            _buildSpecRow('License', 'MIT Open Industrial Standard', isDark),

            const SizedBox(height: 28),
            Center(
              child: Text(
                '© 2026 GearTrack Pro • All Rights Reserved',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF6366F1),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
