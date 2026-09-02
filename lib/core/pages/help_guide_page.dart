import 'package:flutter/material.dart';

class HelpGuidePage extends StatelessWidget {
  const HelpGuidePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const HelpGuidePage());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help & User Guide',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Page Subtitle
            Text(
              'GearTrack Operations Manual',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Essential operating guidelines for inventory, checkout, and verification.',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Module 1
            _buildGuideSection(
              icon: Icons.inventory_2_rounded,
              color: const Color(0xFF4F46E5),
              title: '1. Inventory & Stock Management',
              description:
                  'Keep track of part numbers, stock quantities, and low stock warnings.',
              points: [
                'Add Products: Tap "+" to register part numbers, models, and initial stock.',
                'Stock Count: Adjust stock units directly or through completed POS sales.',
                'Low Stock Alerts: Items with 5 units or fewer are automatically highlighted.',
              ],
              isDark: isDark,
            ),
            const Divider(height: 28),

            // Module 2
            _buildGuideSection(
              icon: Icons.shopping_cart_rounded,
              color: const Color(0xFF10B981),
              title: '2. Point of Sale (POS) Checkout',
              description:
                  'Fast retail billing with automatic inventory depletion.',
              points: [
                'Add to Cart: Quantities are strictly checked against warehouse limits.',
                'Tax & Totals: Computes subtotals, configurable VAT, and final balance.',
                'Invoices: Creates a transaction record with a digital receipt QR code.',
              ],
              isDark: isDark,
            ),
            const Divider(height: 28),

            // Module 3
            _buildGuideSection(
              icon: Icons.qr_code_scanner_rounded,
              color: const Color(0xFFF59E0B),
              title: '3. Receipt Verification Engine',
              description:
                  'Verify authentic sales receipts and prevent counterfeit bills.',
              points: [
                'Live QR Scan: Scan printed receipt QR codes via camera.',
                'Manual Lookup: Search by invoice number if barcode is damaged.',
                'Audit: Shows itemized breakdown, timestamps, and payment status.',
              ],
              isDark: isDark,
            ),
            const Divider(height: 28),

            // Module 4
            _buildGuideSection(
              icon: Icons.vpn_key_rounded,
              color: const Color(0xFF8B5CF6),
              title: '4. Secret Cost Code Cryptography',
              description:
                  'Safeguard your buying prices and profit margins on price tags.',
              points: [
                'Concept: A 10-letter secret word maps characters to numbers 0-9.',
                'Tag Protection: Cost price \$250 displays as letters to hide margins.',
                'Settings: Change your active cost code formula in Shop Settings.',
              ],
              isDark: isDark,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideSection({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required List<String> points,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 10),
        ...points.map((pt) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Expanded(
                  child: Text(
                    pt,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
