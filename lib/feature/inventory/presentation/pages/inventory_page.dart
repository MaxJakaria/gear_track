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
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String? _expandedCardKey;

  @override
  void initState() {
    super.initState();
    // Initial fetch of products
    context.read<InventoryBloc>().add(const FetchProductsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _expandedCardKey = null;
    });
    context.read<InventoryBloc>().add(SearchProductsEvent(query: value));
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
      _expandedCardKey = null;
    });
  }

  void _stopSearch() {
    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = false;
      _expandedCardKey = null;
      _searchController.clear();
    });
    _onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: InventoryAppBar(
          title: 'Products',
          isSearching: _isSearching,
          searchController: _searchController,
          onSearchChanged: _onSearchChanged,
          onStartSearch: _startSearch,
          onStopSearch: _stopSearch,
          onClearSearch: () {
            _searchController.clear();
            _onSearchChanged('');
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => AddProductSheet.show(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Product'),
        ),
        body: BlocConsumer<InventoryBloc, InventoryState>(
          listener: (context, state) {
            if (state is ProductAddedSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green.shade700,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.of(context).maybePop();
            } else if (state is ProductUpdatedSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.blue.shade700,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.of(context).maybePop();
            } else if (state is ProductDeletedSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.orange.shade800,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state is InventoryError) {
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
            return Column(
              children: [
                const SizedBox(height: 8),

                // Product List / Loading / Error View
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (state is InventoryLoading) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading inventory products...'),
                            ],
                          ),
                        );
                      }

                      if (state is InventoryError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Failed to load inventory',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  state.message,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    context.read<InventoryBloc>().add(
                                      const FetchProductsEvent(),
                                    );
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (state is InventoryLoaded) {
                        final groupedProducts = state.filteredGroupedProducts;

                        if (groupedProducts.isEmpty) {
                          return Center(
                            child: SingleChildScrollView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 72,
                                      color: theme.colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchController.text.isNotEmpty
                                          ? 'No matching products found'
                                          : 'No products in inventory yet',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _searchController.text.isNotEmpty
                                          ? 'Try searching with a different term'
                                          : 'Tap the button below to add your first product',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                    if (_searchController.text.isEmpty) ...[
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () =>
                                            AddProductSheet.show(context),
                                        icon: const Icon(Icons.add),
                                        label: const Text('Add Product'),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            context.read<InventoryBloc>().add(
                              const FetchProductsEvent(),
                            );
                          },
                          child: ListView.builder(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: groupedProducts.length,
                            itemBuilder: (context, index) {
                              final grouped = groupedProducts[index];
                              final cardKey =
                                  '${grouped.itemName}_${grouped.model}_${grouped.partNo}';
                              final isExpanded = _expandedCardKey == cardKey;

                              return ProductCard(
                                groupedProduct: grouped,
                                isExpanded: isExpanded,
                                onToggleExpand: () {
                                  setState(() {
                                    if (_expandedCardKey == cardKey) {
                                      _expandedCardKey = null;
                                    } else {
                                      _expandedCardKey = cardKey;
                                    }
                                  });
                                },
                                onQuickAdd: () =>
                                    QuickAddStockSheet.show(context, grouped),
                              );
                            },
                          ),
                        );
                      }


                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
