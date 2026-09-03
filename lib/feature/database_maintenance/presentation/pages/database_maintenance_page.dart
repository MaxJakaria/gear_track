import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/theme/app_colors.dart';
import 'package:gear_track/core/widgets/custom_confirm_delete_dialog.dart';
import 'package:gear_track/feature/database_maintenance/data/models/database_metrics.dart';
import 'package:gear_track/feature/database_maintenance/data/sources/database_maintenance_remote_data_source.dart';
import 'package:gear_track/feature/database_maintenance/presentation/widgets/danger_zone_card.dart';
import 'package:gear_track/feature/database_maintenance/presentation/widgets/database_overview_card.dart';
import 'package:gear_track/feature/database_maintenance/presentation/widgets/maintenance_module_card.dart';
import 'package:gear_track/feature/database_maintenance/presentation/widgets/wipe_confirmation_dialog.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:gear_track/feature/point_of_sale/presentation/bloc/pos_bloc.dart';
import 'package:gear_track/feature/reports/presentation/bloc/reports_bloc.dart';
import 'package:gear_track/feature/returns/presentation/bloc/return_bloc.dart';
import 'package:gear_track/feature/returns/presentation/bloc/return_event.dart';
import 'package:gear_track/init_dependencies.dart';

class DatabaseMaintenancePage extends StatefulWidget {
  const DatabaseMaintenancePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const DatabaseMaintenancePage(),
    );
  }

  @override
  State<DatabaseMaintenancePage> createState() =>
      _DatabaseMaintenancePageState();
}

class _DatabaseMaintenancePageState extends State<DatabaseMaintenancePage> {
  late final DatabaseMaintenanceRemoteDataSource _dataSource;

  DatabaseMetrics _metrics = const DatabaseMetrics();
  bool _isLoadingMetrics = true;

  // Processing state per module
  bool _isClearingSales = false;
  bool _isClearingReturns = false;
  bool _isClearingInventory = false;
  bool _isWipingAll = false;

  bool get _isAnyActionBusy =>
      _isClearingSales ||
      _isClearingReturns ||
      _isClearingInventory ||
      _isWipingAll;

  @override
  void initState() {
    super.initState();
    _dataSource = serviceLocator<DatabaseMaintenanceRemoteDataSource>();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoadingMetrics = true);
    final metrics = await _dataSource.fetchMetrics();
    if (mounted) {
      setState(() {
        _metrics = metrics;
        _isLoadingMetrics = false;
      });
    }
  }

  void _syncAllAppBlocs() {
    if (!mounted) return;
    context.read<InventoryBloc>().add(const FetchProductsEvent());
    context.read<PosBloc>().add(const LoadSalesEvent());
    context.read<PosBloc>().add(const ClearCartEvent());
    context.read<ReturnBloc>().add(const FetchReturnsEvent());
    context.read<ReturnBloc>().add(const ResetReturnStateEvent());
    context.read<ReportsBloc>().add(const RefreshReportsEvent());
  }

  void _showSuccessSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // 1. Clear Sales History
  Future<void> _confirmClearSales() async {
    final confirmed = await CustomConfirmDeleteDialog.show(
      context,
      title: 'Clear Sales History?',
      description:
          'This removes ${_metrics.salesCount} operational sales line records.\n\nCustomer Invoices remain 100% intact for client verification. Lifetime Revenue & Profit remain protected in your Ledger.',
      confirmLabel: 'Clear Sales',
      icon: Icons.delete_sweep_rounded,
      iconColor: const Color(0xFF10B981),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isClearingSales = true);
    try {
      final deletedCount = await _dataSource.clearSalesHistory();
      _syncAllAppBlocs();
      await _loadMetrics();
      _showSuccessSnack(
        'Sales history cleared ($deletedCount lines). Customer invoices & revenue permanently safe.',
      );
    } catch (e) {
      _showErrorSnack('Failed to clear sales: $e');
    } finally {
      if (mounted) setState(() => _isClearingSales = false);
    }
  }

  // 2. Clear Returns History
  Future<void> _confirmClearReturns() async {
    final confirmed = await CustomConfirmDeleteDialog.show(
      context,
      title: 'Clear Returns History?',
      description:
          'This removes ${_metrics.returnsCount} return voucher records and resets refund balances.\n\nSales revenue and stock investment will not be affected.',
      confirmLabel: 'Clear Returns',
      icon: Icons.assignment_return_rounded,
      iconColor: const Color(0xFFF59E0B),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isClearingReturns = true);
    try {
      final deletedCount = await _dataSource.clearReturnsHistory();
      _syncAllAppBlocs();
      await _loadMetrics();
      _showSuccessSnack(
        'Returns history cleared ($deletedCount records removed).',
      );
    } catch (e) {
      _showErrorSnack('Failed to clear returns: $e');
    } finally {
      if (mounted) setState(() => _isClearingReturns = false);
    }
  }

  // 3. Clear Inventory Catalog & Batches
  Future<void> _confirmClearInventory() async {
    final confirmed = await CustomConfirmDeleteDialog.show(
      context,
      title: 'Clear Product Catalog?',
      description:
          'This removes ${_metrics.productsCount} products and ${_metrics.batchesCount} batch entries from active catalog.\n\nTotal Investment capital remains permanently protected in your Financial Ledger.',
      confirmLabel: 'Clear Catalog',
      icon: Icons.inventory_2_rounded,
      iconColor: const Color(0xFF3B82F6),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isClearingInventory = true);
    try {
      final deletedCount = await _dataSource.clearInventoryAndBatches();
      _syncAllAppBlocs();
      await _loadMetrics();
      _showSuccessSnack(
        'Inventory catalog cleared ($deletedCount documents). Lifetime investment preserved.',
      );
    } catch (e) {
      _showErrorSnack('Failed to clear inventory: $e');
    } finally {
      if (mounted) setState(() => _isClearingInventory = false);
    }
  }

  // 4. Complete Factory Wipe
  void _openFactoryWipeChallenge() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => WipeConfirmationDialog(onConfirmed: _executeFactoryWipe),
    );
  }

  Future<void> _executeFactoryWipe() async {
    setState(() => _isWipingAll = true);
    try {
      final totalDeleted = await _dataSource.wipeEntireDatabase();
      _syncAllAppBlocs();
      await _loadMetrics();
      _showSuccessSnack(
        'Factory reset complete! ($totalDeleted documents permanently cleared).',
      );
    } catch (e) {
      _showErrorSnack('Failed to complete factory reset: $e');
    } finally {
      if (mounted) setState(() => _isWipingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Database Maintenance',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadMetrics,
          color: const Color(0xFF6366F1),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live Cloud Metrics Overview
                DatabaseOverviewCard(
                  metrics: _metrics,
                  isLoading: _isLoadingMetrics,
                  onRefresh: _loadMetrics,
                ),
                const SizedBox(height: 10),

                // Friendly Reassurance Banner
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF10B981).withValues(alpha: 0.08)
                        : const Color(0xFFD1FAE5).withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 14,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Invoices & lifetime business profits are permanently preserved.',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF34D399)
                                : const Color(0xFF065F46),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Section 1: Modular Deletions Header
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 11,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'DATA MODULES',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Grouped Modules Container
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.14)
                            : const Color(0xFF64748B).withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Module 1: Sales Transaction History
                      MaintenanceModuleCard(
                        icon: Icons.receipt_long_rounded,
                        iconColor: const Color(0xFF10B981),
                        title: 'Sales History',
                        subtitle:
                            '${_metrics.salesCount} lines • Client invoices remain safe',
                        actionLabel: 'Clear',
                        isProcessing: _isClearingSales,
                        onAction: _isAnyActionBusy ? () {} : _confirmClearSales,
                      ),

                      // Module 2: Returns History
                      MaintenanceModuleCard(
                        icon: Icons.assignment_return_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        title: 'Returns & Refunds',
                        subtitle:
                            '${_metrics.returnsCount} refunds • Stock and margins safe',
                        actionLabel: 'Clear',
                        isProcessing: _isClearingReturns,
                        onAction: _isAnyActionBusy
                            ? () {}
                            : _confirmClearReturns,
                      ),

                      // Module 3: Inventory & Batches
                      MaintenanceModuleCard(
                        icon: Icons.inventory_2_rounded,
                        iconColor: const Color(0xFF3B82F6),
                        title: 'Product Catalog',
                        subtitle:
                            '${_metrics.productsCount} items • Capital preserved in ledger',
                        actionLabel: 'Clear',
                        isProcessing: _isClearingInventory,
                        onAction: _isAnyActionBusy
                            ? () {}
                            : _confirmClearInventory,
                        showDivider: false,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Section 2: Danger Zone Header
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 11,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'DANGER ZONE',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: isDark
                            ? const Color(0xFFF87171)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                DangerZoneCard(
                  isProcessing: _isWipingAll,
                  onWipeDatabase: _isAnyActionBusy
                      ? () {}
                      : _openFactoryWipeChallenge,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
