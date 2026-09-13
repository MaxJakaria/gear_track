import 'package:equatable/equatable.dart';
import 'package:gear_track/feature/returns/domain/entities/return_entity.dart';

/// Represents a paginated slice of return records fetched directly from the database,
/// accompanied by server-aggregated summary statistics.
class PaginatedReturnsEntity extends Equatable {
  /// The list of return records for the requested page.
  final List<ReturnEntity> returns;

  /// Total count of all return records stored in the database.
  final int totalCount;

  /// Server-aggregated sum of all refunded amounts across all returns.
  final double totalRefundsAllTime;

  /// Server-aggregated sum of all returned item quantities across all returns.
  final int totalItemsReturnedAllTime;

  /// Current 1-based page number.
  final int currentPage;

  /// Total number of pages available based on total count and page size.
  final int totalPages;

  /// Whether there are subsequent pages available after this one.
  final bool hasMore;

  const PaginatedReturnsEntity({
    required this.returns,
    required this.totalCount,
    required this.totalRefundsAllTime,
    required this.totalItemsReturnedAllTime,
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [
        returns,
        totalCount,
        totalRefundsAllTime,
        totalItemsReturnedAllTime,
        currentPage,
        totalPages,
        hasMore,
      ];
}
