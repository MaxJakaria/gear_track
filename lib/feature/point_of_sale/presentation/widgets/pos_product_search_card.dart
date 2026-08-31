import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/feature/inventory/domain/entities/grouped_product.dart';
import 'package:gear_track/feature/inventory/domain/entities/product.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:gear_track/feature/point_of_sale/presentation/widgets/pos_search_result_tile.dart';

/// "Find & Add Product" Card Component
class PosProductSearchCard extends StatefulWidget {
  final Function(Product latestBatch, GroupedProduct grouped) onProductSelected;

  const PosProductSearchCard({super.key, required this.onProductSelected});

  @override
  State<PosProductSearchCard> createState() => _PosProductSearchCardState();
}

class _PosProductSearchCardState extends State<PosProductSearchCard> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Header
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF3F51B5), // Blue pill
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Find & Add Product',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Search Field Input Box
          _buildSearchInputField(theme),

          // Live Inventory Search Results List
          _buildSearchResultsList(theme),
        ],
      ),
    );
  }

  Widget _buildSearchInputField(ThemeData theme) {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      onChanged: (val) {
        setState(() {
          _searchQuery = val.trim().toLowerCase();
        });
      },
      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search by name, model or part no...',
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          fontSize: 12,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: theme.colorScheme.onSurfaceVariant,
          size: 18,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 34,
          minHeight: 20,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 34,
          minHeight: 20,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(
                    Icons.clear_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : const SizedBox(width: 34, height: 20),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
      ),
    );
  }

  Widget _buildSearchResultsList(ThemeData theme) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is InventoryLoaded) {
          final allGrouped = state.groupedProducts;

          final filteredGrouped = _searchQuery.isEmpty
              ? <GroupedProduct>[]
              : allGrouped.where((g) {
                  return g.itemName.toLowerCase().contains(_searchQuery) ||
                      g.partNo.toLowerCase().contains(_searchQuery) ||
                      g.model.toLowerCase().contains(_searchQuery);
                }).toList();

          if (_searchQuery.isNotEmpty && filteredGrouped.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Center(
                child: Text(
                  'No matching products found',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }

          if (filteredGrouped.isEmpty) {
            return const SizedBox.shrink();
          }

          return Container(
            margin: const EdgeInsets.only(top: 12),

            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredGrouped.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              itemBuilder: (context, index) {
                final grouped = filteredGrouped[index];
                final latestBatch = grouped.batches.isNotEmpty
                    ? grouped.batches.first
                    : null;

                return PosSearchResultTile(
                  grouped: grouped,
                  onTap: () {
                    if (latestBatch != null) {
                      widget.onProductSelected(latestBatch, grouped);
                      _searchController.clear();
                      _searchFocusNode.unfocus();
                      setState(() {
                        _searchQuery = '';
                      });
                    }
                  },
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
