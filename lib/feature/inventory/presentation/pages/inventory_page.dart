import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<void> _handleClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFD32F2F)),
            SizedBox(width: 8),
            Text('Delete All Products?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete all products and batches from Cloud Firestore? This cannot be undone.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deleting all products...'),
          duration: Duration(seconds: 1),
        ),
      );
      final firestore = FirebaseFirestore.instance;
      final productsSnapshot = await firestore.collection('products').get();
      for (final doc in productsSnapshot.docs) {
        final entriesSnapshot = await doc.reference
            .collection('stock_entries')
            .get();
        for (final entry in entriesSnapshot.docs) {
          await entry.reference.delete();
        }
        await doc.reference.delete();
      }
      if (mounted) {
        context.read<InventoryBloc>().add(const FetchProductsEvent());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All products deleted successfully!'),
            backgroundColor: Color(0xFFD32F2F),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
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
          onClearAll: _handleClearAll,
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
              return _buildErrorView(context, state.message);
            }

            if (state is InventoryLoaded) {
              final groupedList = state.filteredGroupedProducts;

              if (groupedList.isEmpty) {
                return _buildEmptyView(context);
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<InventoryBloc>().add(const FetchProductsEvent());
                },
                child: ListView.separated(
                  separatorBuilder: (context, index) => SizedBox(height: 12),
                  padding: const EdgeInsets.all(16),
                  itemCount: groupedList.length,
                  itemBuilder: (context, index) {
                    final item = groupedList[index];
                    final isCardExpanded = _expandedCardKey == item.itemName;

                    return ProductCard(
                      groupedProduct: item,
                      isExpanded: isCardExpanded,
                      onToggleExpand: () {
                        setState(() {
                          _expandedCardKey = isCardExpanded
                              ? null
                              : item.itemName;
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
                  : 'Tap the "+ Add Product" button below to add your first product.',
              textAlign: TextAlign.center,
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
