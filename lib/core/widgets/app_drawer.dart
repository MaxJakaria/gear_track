import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/theme/app_colors.dart';
import 'package:gear_track/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:gear_track/feature/inventory/presentation/pages/settings_page.dart';
import 'package:gear_track/feature/inventory/presentation/widgets/add_product_sheet.dart';
import 'package:gear_track/feature/receipt_verification/presentation/pages/receipt_verification_page.dart';

class AppDrawer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onNavigateToTab;
  final VoidCallback? onClearAllProducts;

  const AppDrawer({
    super.key,
    this.currentIndex = 0,
    this.onNavigateToTab,
    this.onClearAllProducts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark
        ? AppColors.primaryButtonDark
        : AppColors.primaryButtonLight;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // 1. Header (Executive Profile & Brand)
            _buildDrawerHeader(context, isDark, primaryColor),

            // 2. Scrollable Menu Categories
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                children: [
                  // Section: CORE OPERATIONS
                  _buildSectionHeader('CORE OPERATIONS', isDark),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.inventory_2_rounded,
                    title: 'Inventory & Catalog',
                    subtitle: 'Manage products & stock levels',
                    isSelected: currentIndex == 0,
                    primaryColor: primaryColor,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateToTab?.call(0);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.warning_amber_rounded,
                    title: 'Low Stock Alerts',
                    subtitle: 'Items needing reordering',
                    primaryColor: Colors.amber.shade700,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateToTab?.call(0);
                      context.read<InventoryBloc>().add(
                        const SearchProductsEvent(
                          query: '',
                          filter: StockFilter.lowStock,
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.shopping_cart_rounded,
                    title: 'Point of Sale (POS)',
                    subtitle: 'Fast retail checkout & invoicing',
                    isSelected: currentIndex == 1,
                    primaryColor: primaryColor,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateToTab?.call(1);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.qr_code_scanner_rounded,
                    title: 'Receipt Verification',
                    subtitle: 'Scan & verify sales receipts',
                    primaryColor: const Color(0xFF10B981),
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReceiptVerificationPage(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.add_circle_outline_rounded,
                    title: 'Quick Add Product',
                    subtitle: 'Register new stock item',
                    primaryColor: primaryColor,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      AddProductSheet.show(context);
                    },
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Section: ANALYTICS & INTELLIGENCE
                  _buildSectionHeader('ANALYTICS & INSIGHTS', isDark),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.analytics_rounded,
                    title: 'Financial & Sales Reports',
                    subtitle: 'Revenue, profits & transaction log',
                    isSelected: currentIndex == 2,
                    primaryColor: primaryColor,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateToTab?.call(2);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Stock Valuation Summary',
                    subtitle: 'Real-time inventory asset worth',
                    primaryColor: const Color(0xFF6366F1),
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      _showValuationDialog(context, isDark);
                    },
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Section: STORE & SYSTEM
                  _buildSectionHeader('SYSTEM & STORE', isDark),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.settings_outlined,
                    title: 'Shop & Cost Settings',
                    subtitle: 'Store profile, cost codes & security',
                    primaryColor: primaryColor,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, SettingsPage.route());
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.delete_sweep_outlined,
                    title: 'Clear All Products',
                    subtitle: 'Permanently remove catalog items',
                    primaryColor: Colors.redAccent,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      onClearAllProducts?.call();
                    },
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Section: SUPPORT & DEVELOPER
                  _buildSectionHeader('SUPPORT & DEVELOPER', isDark),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.help_outline_rounded,
                    title: 'Help & User Guide',
                    subtitle: 'App walkthrough & operating manual',
                    primaryColor: const Color(0xFF0284C7),
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      _showHelpDialog(context, isDark);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.code_rounded,
                    title: 'Developer Info',
                    subtitle: 'Engineering credits & project stack',
                    primaryColor: const Color(0xFF8B5CF6),
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      _showDeveloperDialog(context, isDark);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.info_outline_rounded,
                    title: 'About GearTrack',
                    subtitle: 'v1.0.0 Pro • Industrial Suite',
                    primaryColor: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutDialog(context, isDark);
                    },
                  ),
                ],
              ),
            ),

            // 3. Footer (Logout)
            _buildDrawerFooter(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient(context),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.precision_manufacturing_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GearTrack Pro',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Industrial Supply ERP',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Logged-in Admin Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Authorized Admin',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                      Text(
                        AuthBloc.adminEmail,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFE2E8F0)
                              : const Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.shield_outlined,
                  size: 16,
                  color: Color(0xFF10B981),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 6, bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color primaryColor,
    required bool isDark,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? primaryColor.withValues(alpha: isDark ? 0.2 : 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: primaryColor.withValues(alpha: 0.4), width: 1)
            : null,
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: isDark ? 0.3 : 0.15)
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected
                ? primaryColor
                : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? primaryColor
                : (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerFooter(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: ListTile(
        onTap: () => _confirmSignOut(context, isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.logout_rounded,
            color: Color(0xFFEF4444),
            size: 20,
          ),
        ),
        title: const Text(
          'Log Out',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFFEF4444),
          ),
        ),
        subtitle: Text(
          'End current admin session',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
            Text('Confirm Sign Out', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out from GearTrack? You will need to sign in again via admin magic link.',
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

  void _showValuationDialog(BuildContext context, bool isDark) {
    final state = context.read<InventoryBloc>().state;
    int totalSkuModels = 0;
    int totalInStockUnits = 0;
    int lowStockAlertCount = 0;
    int outOfStockCount = 0;

    if (state is InventoryLoaded) {
      totalSkuModels = state.products.length;
      for (final p in state.products) {
        totalInStockUnits += p.stockCount;
        if (p.stockCount == 0) {
          outOfStockCount++;
        } else if (p.stockCount <= 5) {
          lowStockAlertCount++;
        }
      }
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(
              Icons.account_balance_wallet_rounded,
              color: Color(0xFF6366F1),
            ),
            SizedBox(width: 10),
            Text(
              'Stock Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildValuationRow(
              'Total Product SKUs',
              '$totalSkuModels models',
              isDark,
            ),
            const Divider(height: 14),
            _buildValuationRow(
              'Total In-Stock Units',
              '$totalInStockUnits units',
              isDark,
              highlightColor: const Color(0xFF6366F1),
            ),
            const Divider(height: 14),
            _buildValuationRow(
              'Low Stock Alerts (≤5)',
              '$lowStockAlertCount items',
              isDark,
              highlightColor: lowStockAlertCount > 0
                  ? Colors.amber.shade700
                  : null,
            ),
            const Divider(height: 14),
            _buildValuationRow(
              'Out of Stock',
              '$outOfStockCount items',
              isDark,
              highlightColor: outOfStockCount > 0
                  ? const Color(0xFFEF4444)
                  : null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static Widget _buildValuationRow(
    String label,
    String value,
    bool isDark, {
    Color? highlightColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color:
                highlightColor ??
                (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  void _showHelpDialog(BuildContext context, bool isDark) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Color(0xFF0284C7)),
            SizedBox(width: 10),
            Text(
              'Help & User Guide',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHelpItem(
                  icon: Icons.inventory_2_rounded,
                  color: const Color(0xFF4F46E5),
                  title: '1. Inventory Management',
                  description:
                      'Add products, update stock quantities, set buying & selling prices, and monitor low stock alerts.',
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildHelpItem(
                  icon: Icons.shopping_cart_rounded,
                  color: const Color(0xFF10B981),
                  title: '2. Point of Sale (POS)',
                  description:
                      'Search items, add to cart with real-time stock limits, calculate subtotals & taxes, and generate invoices with unique QR codes.',
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildHelpItem(
                  icon: Icons.qr_code_scanner_rounded,
                  color: const Color(0xFFF59E0B),
                  title: '3. Receipt Verification',
                  description:
                      'Scan printed receipt QR codes or enter invoice numbers to instantly verify authentic purchases.',
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildHelpItem(
                  icon: Icons.vpn_key_rounded,
                  color: const Color(0xFF8B5CF6),
                  title: '4. Secret Cost Codes',
                  description:
                      'Cost codes (e.g. 10 letters mapped to digits 0-9) encode your buying prices on price tags so customers cannot read your profit margin.',
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  static Widget _buildHelpItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.25 : 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeveloperDialog(BuildContext context, bool isDark) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6366F1),
                    Color(0xFF8B5CF6),
                    Color(0xFFEC4899),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.terminal_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Max Jakaria',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              'Lead Software & Mobile Engineer',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFF818CF8)
                    : const Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  _buildDevRow(
                    Icons.email_outlined,
                    'Contact',
                    'maxjakaria824@gmail.com',
                    isDark,
                  ),
                  const Divider(height: 14),
                  _buildDevRow(
                    Icons.layers_outlined,
                    'Architecture',
                    'Clean Arch + BLoC',
                    isDark,
                  ),
                  const Divider(height: 14),
                  _buildDevRow(
                    Icons.cloud_outlined,
                    'Backend',
                    'Firebase Firestore & Auth',
                    isDark,
                  ),
                  const Divider(height: 14),
                  _buildDevRow(
                    Icons.school_outlined,
                    'Project',
                    'Final Year Industrial ERP',
                    isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static Widget _buildDevRow(
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF8B5CF6)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context, bool isDark) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(
              Icons.precision_manufacturing_rounded,
              color: Color(0xFF6366F1),
            ),
            SizedBox(width: 10),
            Text(
              'GearTrack Pro',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enterprise Inventory, Point of Sale & Supply Chain Management System.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            Text(
              '• Architecture: Clean Architecture + BLoC\n'
              '• Backend: Google Cloud Firestore & Firebase Auth\n'
              '• Version: 1.0.0 Pro\n'
              '• Security: Passwordless Admin Authentication',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
