import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:gear_track/feature/inventory/presentation/widgets/add_product_sheet.dart';
import 'package:gear_track/feature/inventory/presentation/widgets/inventory_app_bar.dart';
import 'package:gear_track/feature/inventory/presentation/widgets/product_card.dart';
import 'package:gear_track/feature/inventory/presentation/widgets/quick_add_stock_sheet.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

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
    context.read<InventoryBloc>().add(SearchProductsEvent(query: query));
  }

  void _stopSearch() {
    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = false;
      _expandedCardKey = null;
      _searchController.clear();
    });
    _onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
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
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => AddProductSheet.show(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Product'),
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
                  backgroundColor: Colors.red.shade700,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is InventoryLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is InventoryError) {
              return _buildErrorView(context, state.message);
            }

            if (state is InventoryLoaded) {
              final products = state.filteredGroupedProducts;
              if (products.isEmpty) {
                return _buildEmptyView(context);
              }

              return RefreshIndicator(
                onRefresh: () async => context.read<InventoryBloc>().add(
                  const FetchProductsEvent(),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = products[index];
                    final key = '${item.itemName}_${item.model}_${item.partNo}';
                    return ProductCard(
                      key: ValueKey(key),
                      groupedProduct: item,
                      isExpanded: _expandedCardKey == key,
                      onToggleExpand: () {
                        setState(() {
                          _expandedCardKey = _expandedCardKey == key
                              ? null
                              : key;
                        });
                      },
                      onQuickAdd: () => QuickAddStockSheet.show(context, item),
                    );
                  },
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No matching products found'
                  : 'No products in inventory yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Try searching with a different term'
                  : 'Tap below to add your first product',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load inventory',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<InventoryBloc>().add(const FetchProductsEvent()),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
