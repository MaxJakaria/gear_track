import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/theme/app_colors.dart';
import 'package:gear_track/core/utils/currency_formatter.dart';
import 'package:gear_track/feature/returns/domain/entities/return_entity.dart';
import 'package:gear_track/feature/returns/presentation/bloc/return_bloc.dart';
import 'package:gear_track/feature/returns/presentation/bloc/return_event.dart';
import 'package:gear_track/feature/returns/presentation/bloc/return_state.dart';
import 'package:gear_track/feature/returns/presentation/widgets/return_history_card.dart';

/// Tab 2 of Returns Hub: Displays database-paginated completed returns,
/// metrics summary, and PDF voucher reprint action.
class ReturnHistoryTab extends StatelessWidget {
  final ReturnState state;
  final Future<void> Function(ReturnEntity returnRecord) onPrintVoucher;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;

  const ReturnHistoryTab({
    super.key,
    required this.state,
    required this.onPrintVoucher,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final List<ReturnEntity> returnsList;
    final int currentPage;
    final int totalPages;
    final int totalCount;
    final double totalRefunds;
    final int totalItemsCount;
    final bool isHistoryLoading;

    if (state is ReturnsLoadedSuccess) {
      final success = state as ReturnsLoadedSuccess;
      returnsList = success.returns;
      currentPage = success.currentPage;
      totalPages = success.totalPages;
      totalCount = success.totalCount;
      totalRefunds = success.totalRefundsAllTime;
      totalItemsCount = success.totalItemsReturnedAllTime;
      isHistoryLoading = success.isHistoryLoading;
    } else {
      returnsList = [];
      currentPage = 1;
      totalPages = 1;
      totalCount = 0;
      totalRefunds = 0.0;
      totalItemsCount = 0;
      isHistoryLoading = state is ReturnLoading;
    }

    final int startItem = totalCount == 0 ? 0 : (currentPage - 1) * 10 + 1;
    final int endItem = totalCount == 0
        ? 0
        : (startItem + returnsList.length - 1).clamp(startItem, totalCount);

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ReturnBloc>().add(
          const FetchReturnsEvent(page: 1, forceRefresh: true),
        );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Minimal Metrics Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL REFUNDED',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        totalRefunds.toCurrency(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                          color: isDark
                              ? const Color(0xFFF87171)
                              : const Color(0xFFE11D48),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$totalCount ${totalCount == 1 ? 'Return' : 'Returns'}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '$totalItemsCount Items',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Past Returns Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PAST RETURNS LOG',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    if (isHistoryLoading) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark
                                ? AppColors.primaryButtonDark
                                : AppColors.primaryButtonLight,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (totalCount > 0)
                  Text(
                    'Showing $startItem–$endItem of $totalCount',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Returns List or Empty View
            if (returnsList.isEmpty && !isHistoryLoading)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 36,
                  horizontal: 20,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor, width: 0.8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment_turned_in_outlined,
                      size: 40,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No Returns Recorded Yet',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Returned items and refunds will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              ...returnsList.map((ret) {
                return ReturnHistoryCard(
                  returnRecord: ret,
                  onPrintVoucher: () => onPrintVoucher(ret),
                );
              }),

              // Database Pagination Controls
              if (totalPages > 1) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 0.8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous Page Button
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 14,
                        ),
                        tooltip: 'Previous Page',
                        color: (currentPage > 1 && !isHistoryLoading)
                            ? (isDark
                                  ? AppColors.primaryButtonDark
                                  : AppColors.primaryButtonLight)
                            : (isDark
                                  ? const Color(0xFF475569)
                                  : const Color(0xFFCBD5E1)),
                        onPressed: (currentPage > 1 && !isHistoryLoading)
                            ? () {
                                context.read<ReturnBloc>().add(
                                  FetchReturnsEvent(page: currentPage - 1),
                                );
                              }
                            : null,
                      ),

                      // Page Indicator
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Page $currentPage of $totalPages',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF334155),
                            ),
                          ),
                          if (isHistoryLoading) ...[
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDark
                                      ? AppColors.primaryButtonDark
                                      : AppColors.primaryButtonLight,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Next Page Button
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                        ),
                        tooltip: 'Next Page',
                        color: (currentPage < totalPages && !isHistoryLoading)
                            ? (isDark
                                  ? AppColors.primaryButtonDark
                                  : AppColors.primaryButtonLight)
                            : (isDark
                                  ? const Color(0xFF475569)
                                  : const Color(0xFFCBD5E1)),
                        onPressed: (currentPage < totalPages && !isHistoryLoading)
                            ? () {
                                context.read<ReturnBloc>().add(
                                  FetchReturnsEvent(page: currentPage + 1),
                                );
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
