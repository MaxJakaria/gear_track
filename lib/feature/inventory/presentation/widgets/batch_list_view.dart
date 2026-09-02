import 'package:flutter/material.dart';
import 'package:gear_track/feature/inventory/domain/entities/grouped_product.dart';
import 'package:gear_track/feature/inventory/presentation/widgets/batch_card.dart';

class BatchListView extends StatelessWidget {
  final List<GroupedProduct> groupedBatches;
  final Future<void> Function() onRefresh;

  const BatchListView({
    super.key,
    required this.groupedBatches,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: groupedBatches.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final grouped = groupedBatches[index];
          return BatchCard(
            groupedProduct: grouped,
            cardIndex: index,
          );
        },
      ),
    );
  }
}
