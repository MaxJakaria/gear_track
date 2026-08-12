import 'package:flutter/material.dart';

class InventoryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isSearching;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onStartSearch;
  final VoidCallback onStopSearch;
  final VoidCallback onClearSearch;
  final String title;

  const InventoryAppBar({
    super.key,
    required this.isSearching,
    required this.searchController,
    required this.onSearchChanged,
    required this.onStartSearch,
    required this.onStopSearch,
    required this.onClearSearch,
    required this.title,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      leading: isSearching
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: onStopSearch,
            )
          : null,
      titleSpacing: isSearching ? 0 : null,
      title: isSearching
          ? ValueListenableBuilder<TextEditingValue>(
              valueListenable: searchController,
              builder: (context, value, child) {
                return Container(
                  height: 42,
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.6,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/icons/search-engine.png',
                        width: 18,
                        height: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          autofocus: true,
                          onChanged: onSearchChanged,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search by part-no/name/model...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (value.text.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: onClearSearch,
                          child: Icon(
                            Icons.cancel_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            )
          : Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
      actions: [
        if (!isSearching)
          IconButton(
            icon: Image.asset(
              'assets/icons/search-engine.png',
              width: 24,
              height: 24,
            ),
            tooltip: 'Search Products',
            onPressed: onStartSearch,
          ),
      ],
    );
  }
}
