import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/pages/about_page.dart';
import 'package:gear_track/core/pages/help_guide_page.dart';
import 'package:gear_track/core/widgets/app_gradient_button.dart';
import 'package:gear_track/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:gear_track/feature/inventory/presentation/pages/settings_page.dart';

class AppDrawer extends StatefulWidget {
  final VoidCallback? onClearAllProducts;

  const AppDrawer({super.key, this.onClearAllProducts});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  StockFilter? _selectedFilter;
  bool _filterMenuOpen = false;
  bool _lowStockOpen = true;
  bool _outOfStockOpen = false;

  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _storeStream;

  @override
  void initState() {
    super.initState();
    _storeStream = FirebaseFirestore.instance
        .collection('app_settings')
        .doc('shop_settings')
        .snapshots();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedFilter == null) {
      final inventoryState = context.read<InventoryBloc>().state;
      if (inventoryState is InventoryLoaded) {
        _selectedFilter = inventoryState.activeFilter;
        if (_selectedFilter != StockFilter.all) {
          _filterMenuOpen = true;
        }
        if (_selectedFilter == StockFilter.lowStockProduct ||
            _selectedFilter == StockFilter.lowStockBatch) {
          _lowStockOpen = true;
        } else if (_selectedFilter == StockFilter.outOfStockProduct ||
            _selectedFilter == StockFilter.outOfStockBatch) {
          _outOfStockOpen = true;
        }
      } else {
        _selectedFilter = StockFilter.all;
      }
    }
  }

  void _onSelectFilter(StockFilter filter) {
    setState(() {
      _selectedFilter = (_selectedFilter == filter) ? StockFilter.all : filter;
    });
  }

  void _applyFilter(BuildContext context) {
    final inventoryState = context.read<InventoryBloc>().state;
    final currentQuery = inventoryState is InventoryLoaded
        ? inventoryState.searchQuery
        : '';

    context.read<InventoryBloc>().add(
      SearchProductsEvent(
        query: currentQuery,
        filter: _selectedFilter ?? StockFilter.all,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final menuIconColor = isDark
        ? const Color(0xFF818CF8)
        : const Color(0xFF4F46E5);

    return Drawer(
      width: 290,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: Colors.transparent,
      child: Row(
        children: [
          // Outer Soft Shadow Strip (on the left edge for right-side slide)
          Container(
            width: 16,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Colors.white.withValues(alpha: 0.16),
                  Colors.white.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // Main Drawer Body
          Expanded(
            child: ColoredBox(
              color: isDark ? const Color(0xFF0B0F19) : Colors.white,
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // 1. Live Store Profile Card
                    _buildStoreProfileCard(context, isDark),

                    const SizedBox(height: 10),

                    // 2. Pure Text-Based Filter Menu Card
                    _buildTextBasedFilterMenu(context, isDark, menuIconColor),

                    const SizedBox(height: 14),

                    // Section Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Text(
                        'MANAGEMENT & HELP',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // 3. Clear All Products
                    _buildMenuCard(
                      icon: Icons.delete_sweep_rounded,
                      title: 'Clear All Products',
                      iconColor: menuIconColor,
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onClearAllProducts?.call();
                      },
                    ),

                    // 4. Help & User Guide
                    _buildMenuCard(
                      icon: Icons.help_rounded,
                      title: 'Help & User Guide',
                      iconColor: menuIconColor,
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, HelpGuidePage.route());
                      },
                    ),

                    // 5. About GearTrack
                    _buildMenuCard(
                      icon: Icons.info_rounded,
                      title: 'About',
                      iconColor: menuIconColor,
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
                      iconColor: menuIconColor,
                      isDark: isDark,
                      onTap: () => _confirmSignOut(context, isDark),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextBasedFilterMenu(
    BuildContext context,
    bool isDark,
    Color iconColor,
  ) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        int inStockCount = 0;
        int lowProductCount = 0;
        int lowBatchCount = 0;
        int outProductCount = 0;
        int outBatchCount = 0;

        if (state is InventoryLoaded) {
          inStockCount = state.inStockCount;
          lowProductCount = state.lowStockProductCount;
          lowBatchCount = state.lowStockBatchCount;
          outProductCount = state.outOfStockProductCount;
          outBatchCount = state.outOfStockBatchCount;
        }

        final selected = _selectedFilter ?? StockFilter.all;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131B2E) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Filter Header
              GestureDetector(
                onTap: () => setState(() => _filterMenuOpen = !_filterMenuOpen),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(
                            alpha: isDark ? 0.2 : 0.14,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: iconColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                            color: isDark
                                ? const Color(0xFFF8FAFC)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: _filterMenuOpen ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Expandable Filter Body
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.topCenter,
                clipBehavior: Clip.hardEdge,
                child: _filterMenuOpen
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: isDark
                                  ? const Color(
                                      0xFF334155,
                                    ).withValues(alpha: 0.3)
                                  : const Color(0xFFE2E8F0),
                            ),
                            const SizedBox(height: 6),

                            // In Stock Filter
                            _buildTextRow(
                              title: 'In Stock',
                              count: inStockCount,
                              isSelected: selected == StockFilter.inStock,
                              isDark: isDark,
                              onTap: () => _onSelectFilter(StockFilter.inStock),
                            ),

                            const SizedBox(height: 3),

                            // Low Stock Accordion
                            _buildTextAccordion(
                              title: 'Low Stock',
                              isExpanded: _lowStockOpen,
                              isDark: isDark,
                              onToggle: () => setState(
                                () => _lowStockOpen = !_lowStockOpen,
                              ),
                              children: [
                                _buildTextSubRow(
                                  title: 'Product',
                                  count: lowProductCount,
                                  isSelected:
                                      selected == StockFilter.lowStockProduct,
                                  isDark: isDark,
                                  onTap: () => _onSelectFilter(
                                    StockFilter.lowStockProduct,
                                  ),
                                ),
                                _buildTextSubRow(
                                  title: 'Batch',
                                  count: lowBatchCount,
                                  isSelected:
                                      selected == StockFilter.lowStockBatch,
                                  isDark: isDark,
                                  onTap: () => _onSelectFilter(
                                    StockFilter.lowStockBatch,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 3),

                            // Out of Stock Accordion
                            _buildTextAccordion(
                              title: 'Out of Stock',
                              isExpanded: _outOfStockOpen,
                              isDark: isDark,
                              onToggle: () => setState(
                                () => _outOfStockOpen = !_outOfStockOpen,
                              ),
                              children: [
                                _buildTextSubRow(
                                  title: 'Product',
                                  count: outProductCount,
                                  isSelected:
                                      selected == StockFilter.outOfStockProduct,
                                  isDark: isDark,
                                  onTap: () => _onSelectFilter(
                                    StockFilter.outOfStockProduct,
                                  ),
                                ),
                                _buildTextSubRow(
                                  title: 'Batch',
                                  count: outBatchCount,
                                  isSelected:
                                      selected == StockFilter.outOfStockBatch,
                                  isDark: isDark,
                                  onTap: () => _onSelectFilter(
                                    StockFilter.outOfStockBatch,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // "Show Result" Button
                            AppGradientButton(
                              label: 'Show Result',
                              height: 34,
                              borderRadius: 6,
                              fontSize: 12.5,
                              onPressed: () => _applyFilter(context),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextRow({
    required String title,
    required int count,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : (isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF475569)),
                ),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextAccordion({
    required String title,
    required bool isExpanded,
    required bool isDark,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          clipBehavior: Clip.hardEdge,
          child: isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Column(children: children),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildTextSubRow({
    required String title,
    required int count,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : (isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF475569)),
                ),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreProfileCard(BuildContext context, bool isDark) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _storeStream,
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
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/logos/app_logo.png',
                        width: 30,
                        height: 30,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
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
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
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
                              fontSize: 13,
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
                              fontSize: 10,
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
                      size: 16,
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
      margin: const EdgeInsets.only(bottom: 6),
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
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: isDark ? 0.2 : 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(child: Icon(icon, size: 16, color: iconColor)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
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
                  size: 16,
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
