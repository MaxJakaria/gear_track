import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/pages/about_page.dart';
import 'package:gear_track/core/pages/developer_info_page.dart';
import 'package:gear_track/core/pages/help_guide_page.dart';
import 'package:gear_track/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:gear_track/feature/inventory/presentation/pages/settings_page.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback? onClearAllProducts;

  const AppDrawer({super.key, this.onClearAllProducts});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      width: 320,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: Colors.transparent,
      child: Row(
        children: [
          // Main Drawer Body
          Expanded(
            child: ColoredBox(
              color: isDark ? const Color(0xFF0B0F19) : Colors.white,
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 1. Live Store Profile Card
                    _buildStoreProfileCard(context, isDark),

                    // 2. Clear All Products
                    _buildMenuCard(
                      icon: Icons.delete_sweep_rounded,
                      title: 'Clear All Products',
                      iconColor: const Color(0xFFEAB308),
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        onClearAllProducts?.call();
                      },
                    ),

                    // 3. Help & User Guide
                    _buildMenuCard(
                      icon: Icons.help_rounded,
                      title: 'Help & User Guide',
                      iconColor: const Color(0xFF3B82F6),
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, HelpGuidePage.route());
                      },
                    ),

                    // 4. Developer Info
                    _buildMenuCard(
                      icon: Icons.code_rounded,
                      title: 'Developer Info',
                      iconColor: const Color(0xFFA855F7),
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, DeveloperInfoPage.route());
                      },
                    ),

                    // 5. About GearTrack
                    _buildMenuCard(
                      icon: Icons.info_rounded,
                      title: 'About GearTrack',
                      iconColor: const Color(0xFF0284C7),
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, AboutPage.route());
                      },
                    ),

                    // 6. Log Out
                    _buildMenuCard(
                      icon: Icons.logout_rounded,
                      title: 'Log Out',
                      iconColor: const Color(0xFFEF4444),
                      isDark: isDark,
                      onTap: () => _confirmSignOut(context, isDark),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Outer Right-Side Soft Gradient Shadow Strip
          Container(
            width: 15,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: isDark ? 0.85 : 0.4),
                  Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
                  Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreProfileCard(BuildContext context, bool isDark) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('app_settings')
          .doc('shop_settings')
          .snapshots(),
      builder: (context, snapshot) {
        String shopName = '';
        String address = '';
        String phone = '';

        if (snapshot.hasData &&
            snapshot.data!.exists &&
            snapshot.data!.data() != null) {
          final data = snapshot.data!.data()!;
          shopName = (data['shopName'] as String?)?.trim() ?? '';
          address = (data['address'] as String?)?.trim() ?? '';
          phone = (data['phone'] as String?)?.trim() ?? '';
        }

        final titleText = shopName.isNotEmpty ? shopName : 'Store Profile';
        final subtitleText = address.isNotEmpty
            ? address
            : (phone.isNotEmpty ? phone : 'Tap to configure store');

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131B2E) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, SettingsPage.route());
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.storefront_rounded,
                          size: 17,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titleText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            subtitleText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: isDark ? 0.2 : 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(child: Icon(icon, size: 18, color: iconColor)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: isDark
                      ? const Color(0xFF475569)
                      : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, bool isDark) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 10),
            Text(
              'Confirm Log Out',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of GearTrack?',
          style: TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              Navigator.pop(context); // close drawer
              context.read<AuthBloc>().add(const AuthSignOutRequested());
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
