import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/widgets/app_drawer.dart';
import 'package:gear_track/core/widgets/custom_confirm_delete_dialog.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:gear_track/feature/inventory/presentation/widgets/add_product_fab.dart';
import 'package:gear_track/feature/inventory/presentation/widgets/add_product_sheet.dart';
import 'package:gear_track/feature/inventory/presentation/pages/settings_page.dart';
import 'package:gear_track/feature/inventory/presentation/widgets/clear_inventory_dialog.dart';
import 'package:gear_track/feature/inventory/presentation/widgets/inventory_app_bar.dart';
import 'package:gear_track/feature/inventory/presentation/widgets/inventory_empty_view.dart';
import 'package:gear_track/feature/inventory/presentation/widgets/inventory_error_view.dart';
import 'package:gear_track/feature/inventory/presentation/widgets/product_list_view.dart';
import 'package:gear_track/feature/inventory/presentation/widgets/batch_list_view.dart';
import 'package:gear_track/feature/inventory/presentation/widgets/active_filter_banner.dart';

/// Clean Architecture Inventory Presentation Page
class InventoryPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;

  const InventoryPage({super.key, this.onNavigateToTab});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  String? _expandedCardKey;

  @override
  void initState() {
    super.initState();
    context.read<InventoryBloc>().add(const FetchProductsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() => _expandedCardKey = null);
    final currentFilter =
        (context.read<InventoryBloc>().state is InventoryLoaded)
            ? (context.read<InventoryBloc>().state as InventoryLoaded)
                .activeFilter
            : StockFilter.all;
    context.read<InventoryBloc>().add(
          SearchProductsEvent(query: query, filter: currentFilter),
        );
  }

  void _stopSearch() {
    FocusScope.of(context).unfocus();
    final currentFilter =
        (context.read<InventoryBloc>().state is InventoryLoaded)
            ? (context.read<InventoryBloc>().state as InventoryLoaded)
                .activeFilter
            : StockFilter.all;
    setState(() {
      _isSearching = false;
      _expandedCardKey = null;
      _searchController.clear();
    });
    context.read<InventoryBloc>().add(
          SearchProductsEvent(query: '', filter: currentFilter),
        );
  }

  Future<void> _handleClearAll() async {
    final confirmed = await ClearInventoryDialog.show(context);
    if (confirmed != true || !mounted) return;

    final completer = Completer<void>();
    context.read<InventoryBloc>().add(
          ClearAllProductsEvent(completer: completer),
        );

    try {
      await completer.future;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All products deleted successfully!'),
            backgroundColor: Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete products: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleClearOutOfStockBatches() async {
    final completer = Completer<void>();
    context.read<InventoryBloc>().add(
          ClearOutOfStockBatchesEvent(completer: completer),
        );

    try {
      await completer.future;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All out of stock batches deleted successfully!'),
            backgroundColor: Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete out of stock batches: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        endDrawer: AppDrawer(
          onClearAllProducts: _handleClearAll,
        ),
        appBar: InventoryAppBar(
          title: 'Products',
          isSearching: _isSearching,
          searchController: _searchController,
          onSearchChanged: _onSearch,
          onStartSearch: () => setState(() => _isSearching = true),
          onStopSearch: _stopSearch,
          onClearSearch: () {
            _searchController.clear();
            _onSearch('');
          },
          onClearAll: _handleClearAll,
          onOpenSettings: () =>
              Navigator.push(context, SettingsPage.route()),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: AddProductFab(
          onPressed: () => AddProductSheet.show(context),
        ),
        body: BlocConsumer<InventoryBloc, InventoryState>(
          buildWhen: (_, current) =>
              current is InventoryLoading ||
              current is InventoryLoaded ||
              current is InventoryError,
          listener: (context, state) {
            if (state is InventoryError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is InventoryLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is InventoryError && state.message.isNotEmpty) {
              return InventoryErrorView(
                message: state.message,
                onRetry: () => context
                    .read<InventoryBloc>()
                    .add(const FetchProductsEvent()),
              );
            }

            if (state is InventoryLoaded) {
              final isBatchFilter =
                  state.activeFilter == StockFilter.lowStockBatch ||
                  state.activeFilter == StockFilter.outOfStockBatch;

              final batchList = state.filteredBatches;
              final groupedBatchList = state.filteredBatchesGrouped;
              final groupedProductList = state.filteredGroupedProducts;
              final displayCount = isBatchFilter
                  ? batchList.length
                  : groupedProductList.length;

              return Column(
                children: [
                  // Active Filter Banner (shown only when a filter is applied)
                  Builder(
                    builder: (scaffoldCtx) => ActiveFilterBanner(
                      activeFilter: state.activeFilter,
                      count: displayCount,
                      onClearFilter: () {
                        setState(() => _expandedCardKey = null);
                        context.read<InventoryBloc>().add(
                              SearchProductsEvent(
                                query: _searchController.text,
                                filter: StockFilter.all,
                              ),
                            );
                      },
                      onOpenFilterSidebar: () =>
                          Scaffold.of(scaffoldCtx).openDrawer(),
                      onClearAll: state.activeFilter ==
                                  StockFilter.outOfStockBatch &&
                              batchList.isNotEmpty
                          ? () async {
                              final confirmed =
                                  await CustomConfirmDeleteDialog.show(
                                context,
                                title: 'Clear Out of Stock Batches',
                                description:
                                    'Are you sure you want to delete all ${batchList.length} out-of-stock batch entries across ${groupedBatchList.length} product(s)?\n\n'
                                    'This action cannot be undone.',
                                confirmLabel: 'Clear All',
                              );
                              if (confirmed == true) {
                                _handleClearOutOfStockBatches();
                              }
                            }
                          : null,
                    ),
                  ),

                  // Products / Batches List or Empty View
                  Expanded(
                    child: isBatchFilter
                        ? (groupedBatchList.isEmpty
                            ? InventoryEmptyView(
                                hasSearch: _searchController.text.isNotEmpty,
                                activeFilter: state.activeFilter,
                                onClearSearch: () {
                                  _searchController.clear();
                                  _onSearch('');
                                },
                                onResetFilter: () {
                                  context.read<InventoryBloc>().add(
                                        SearchProductsEvent(
                                          query: _searchController.text,
                                          filter: StockFilter.all,
                                        ),
                                      );
                                },
                              )
                            : BatchListView(
                                groupedBatches: groupedBatchList,
                                onRefresh: () async {
                                  context.read<InventoryBloc>().add(
                                        const FetchProductsEvent(),
                                      );
                                },
                              ))
                        : (groupedProductList.isEmpty
                            ? InventoryEmptyView(
                                hasSearch: _searchController.text.isNotEmpty,
                                activeFilter: state.activeFilter,
                                onClearSearch: () {
                                  _searchController.clear();
                                  _onSearch('');
                                },
                                onResetFilter: () {
                                  context.read<InventoryBloc>().add(
                                        SearchProductsEvent(
                                          query: _searchController.text,
                                          filter: StockFilter.all,
                                        ),
                                      );
                                },
                              )
                            : ProductListView(
                                products: groupedProductList,
                                expandedCardKey: _expandedCardKey,
                                onToggleExpand: (key) {
                                  setState(() => _expandedCardKey = key);
                                },
                                onRefresh: () async {
                                  context.read<InventoryBloc>().add(
                                        const FetchProductsEvent(),
                                      );
                                },
                              )),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
