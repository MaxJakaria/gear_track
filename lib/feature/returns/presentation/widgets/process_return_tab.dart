import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/theme/app_colors.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';
import 'package:gear_track/feature/receipt_verification/presentation/pages/receipt_verification_page.dart';
import 'package:gear_track/feature/returns/presentation/bloc/return_bloc.dart';
import 'package:gear_track/feature/returns/presentation/bloc/return_event.dart';
import 'package:gear_track/feature/returns/presentation/bloc/return_state.dart';
import 'package:gear_track/feature/returns/presentation/widgets/invoice_search_result_card.dart';

/// Tab 1 of Returns Hub: Search sold invoices strictly by Customer Name (partyName)
/// or Invoice ID (invoiceId), inspect products in expandable cards, and proceed to return.
class ProcessReturnTab extends StatefulWidget {
  final TextEditingController searchController;
  final ReturnState state;
  final VoidCallback onSearch;
  final VoidCallback onClearSearch;
  final void Function(InvoiceEntity invoice, {int? initialItemIndex})
  onOpenProcessReturn;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;

  const ProcessReturnTab({
    super.key,
    required this.searchController,
    required this.state,
    required this.onSearch,
    required this.onClearSearch,
    required this.onOpenProcessReturn,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
  });

  @override
  State<ProcessReturnTab> createState() => _ProcessReturnTabState();
}

class _ProcessReturnTabState extends State<ProcessReturnTab> {
  String? _expandedInvoiceId;

  void _toggleExpand(String invoiceId) {
    setState(() {
      _expandedInvoiceId = (_expandedInvoiceId == invoiceId) ? null : invoiceId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final cardBg = widget.cardBg;
    final borderColor = widget.borderColor;
    final state = widget.state;
    final searchController = widget.searchController;
    final onClearSearch = widget.onClearSearch;
    final onSearch = widget.onSearch;
    final onOpenProcessReturn = widget.onOpenProcessReturn;

    final bool isSearching =
        state is ReturnsLoadedSuccess && state.isSearchingInvoice;
    final bool hasSearched =
        state is ReturnsLoadedSuccess && state.hasSearched;
    final List<InvoiceEntity> searchResults =
        (state is ReturnsLoadedSuccess && state.searchedInvoices != null)
            ? state.searchedInvoices!
                .where((inv) =>
                    !inv.isFullyReturned && inv.remainingReturnableItems > 0)
                .toList()
            : [];
    final String currentQuery =
        state is ReturnsLoadedSuccess ? state.searchQuery : '';

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ReturnBloc>().add(const FetchReturnsEvent(page: 1));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Box (Customer Name or Invoice ID strictly)
            TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Search by Customer Name or Invoice ID...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                ),
                filled: true,
                fillColor: cardBg,
                isDense: true,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor, width: 0.8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor, width: 0.8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.primaryButtonDark
                        : AppColors.primaryButtonLight,
                    width: 1.2,
                  ),
                ),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: searchController,
                  builder: (context, value, _) {
                    if (value.text.isNotEmpty) {
                      return IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        tooltip: 'Clear',
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        onPressed: onClearSearch,
                      );
                    }
                    return IconButton(
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 19),
                      tooltip: 'Scan Receipt',
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReceiptVerificationPage(
                              allowReturn: true,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              onSubmitted: (_) => onSearch(),
            ),

            const SizedBox(height: 16),

            // Content based on search state
            if (isSearching)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'Searching sales records...',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              )
            else if (hasSearched) ...[
              if (searchResults.isNotEmpty) ...[
                // Results Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'FOUND ${searchResults.length} ${searchResults.length == 1 ? 'SALE RECORD' : 'SALE RECORDS'}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      'Tap card to inspect items',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Search Results List (Only 1 item expanded at a time, 8 gap)
                ...searchResults.map((inv) {
                  return InvoiceSearchResultCard(
                    invoice: inv,
                    isExpanded: _expandedInvoiceId == inv.invoiceId,
                    onToggleExpand: () => _toggleExpand(inv.invoiceId),
                    onProceedToReturn: () => onOpenProcessReturn(inv),
                  );
                }),
              ] else ...[
                // Empty Search State ("other wise faka thakbe list")
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 48,
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
                        Icons.search_off_rounded,
                        size: 42,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No Sales Records Found',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No sold invoices match "$currentQuery".\nOnly sold products can be returned.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.4,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              // Initial Prompt View before search
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
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
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color:
                            (isDark
                                    ? AppColors.primaryButtonDark
                                    : AppColors.primaryButtonLight)
                                .withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.manage_search_rounded,
                        size: 28,
                        color: isDark
                            ? AppColors.primaryButtonDark
                            : AppColors.primaryButtonLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Search Sold Products by Customer or Invoice',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter customer name (user name) or invoice ID to locate sold items and initiate a return.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReceiptVerificationPage(
                              allowReturn: true,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                      label: const Text(
                        'Scan Receipt QR',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? AppColors.primaryButtonDark
                            : AppColors.primaryButtonLight,
                        side: BorderSide(
                          color: isDark
                              ? AppColors.primaryButtonDark
                              : AppColors.primaryButtonLight,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
