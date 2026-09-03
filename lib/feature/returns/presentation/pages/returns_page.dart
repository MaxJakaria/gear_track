import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/domain/usecases/get_shop_settings.dart';
import 'package:gear_track/core/entities/shop_settings.dart';
import 'package:gear_track/core/theme/app_colors.dart';
import 'package:gear_track/core/utils/currency_formatter.dart';
import 'package:gear_track/feature/point_of_sale/presentation/pages/pdf_preview_page.dart';
import 'package:gear_track/feature/receipt_verification/presentation/pages/receipt_verification_page.dart';
import 'package:gear_track/feature/returns/domain/entities/return_entity.dart';
import 'package:gear_track/feature/returns/presentation/bloc/return_bloc.dart';
import 'package:gear_track/feature/returns/presentation/bloc/return_event.dart';
import 'package:gear_track/feature/returns/presentation/bloc/return_state.dart';
import 'package:gear_track/feature/returns/presentation/pages/process_return_page.dart';
import 'package:gear_track/feature/returns/presentation/widgets/return_history_card.dart';
import 'package:gear_track/feature/returns/utils/pdf_return_voucher_service.dart';
import 'package:gear_track/init_dependencies.dart';

/// Minimalist, high-end returns & refunds hub matching GearTrack's luxury UI
class ReturnsPage extends StatefulWidget {
  const ReturnsPage({super.key});

  @override
  State<ReturnsPage> createState() => _ReturnsPageState();
}

class _ReturnsPageState extends State<ReturnsPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchingInvoice = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final returnState = context.read<ReturnBloc>().state;
    if (returnState is! ReturnsLoadedSuccess) {
      context.read<ReturnBloc>().add(const FetchReturnsEvent());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  void _searchInvoice() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _isSearchingInvoice = true;
    });
    context.read<ReturnBloc>().add(FetchInvoiceForReturnEvent(query));
  }

  Future<void> _reprintVoucher(ReturnEntity returnRecord) async {
    ShopSettings shopSettings = const ShopSettings();
    try {
      final getShopSettings = serviceLocator<GetShopSettings>();
      final result = await getShopSettings();
      result.fold((_) {}, (settings) => shopSettings = settings);
    } catch (_) {}

    try {
      final doc = await PdfReturnVoucherService.generateReturnVoucher(
        returnRecord: returnRecord,
        shopSettings: shopSettings,
      );
      final bytes = await doc.save();

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PdfPreviewPage(pdfBytes: bytes)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load voucher: $e'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Returns & Refunds',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<ReturnBloc, ReturnState>(
          listener: (context, state) {
            if (state is! ReturnLoading && _isSearchingInvoice) {
              setState(() {
                _isSearchingInvoice = false;
              });
            }
            if (state is InvoiceLoadedForReturnSuccess) {
              _isSearchingInvoice = false;
              _clearSearch();
              final invoice = state.invoice;
              context.read<ReturnBloc>().add(ResetReturnStateEvent());
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProcessReturnPage(invoice: invoice),
                ),
              );
            } else if (state is ReturnFailure) {
              _isSearchingInvoice = false;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage),
                  backgroundColor: const Color(0xFFD32F2F),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            final List<ReturnEntity> returnsList;
            double totalRefunds = 0.0;
            int totalItemsCount = 0;

            if (state is ReturnsLoadedSuccess) {
              returnsList = state.returns;
              totalRefunds = state.totalRefundsAllTime;
              totalItemsCount = state.totalItemsReturnedAllTime;
            } else {
              returnsList = [];
            }

            final isSearching = _isSearchingInvoice && state is ReturnLoading;

            return RefreshIndicator(
              onRefresh: () async {
                context.read<ReturnBloc>().add(const FetchReturnsEvent());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Minimal Metrics Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.25 : 0.03,
                            ),
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
                                  '${returnsList.length} ${returnsList.length == 1 ? 'Return' : 'Returns'}',
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

                    const SizedBox(height: 12),

                    // Minimal Invoice ID Input & QR Shortcut
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim().toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter Invoice ID...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        filled: true,
                        fillColor: cardBg,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
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
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                tooltip: 'Clear',
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                                onPressed: _clearSearch,
                              ),
                            IconButton(
                              icon: const Icon(
                                Icons.qr_code_scanner_rounded,
                                size: 20,
                              ),
                              tooltip: 'Scan Receipt',
                              color: isDark
                                  ? AppColors.primaryButtonDark
                                  : AppColors.primaryButtonLight,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ReceiptVerificationPage(),
                                  ),
                                );
                              },
                            ),
                            if (isSearching)
                              const Padding(
                                padding: EdgeInsets.only(right: 12, left: 4),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            else
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 20,
                                ),
                                tooltip: 'Process Return',
                                onPressed: _searchInvoice,
                              ),
                          ],
                        ),
                      ),
                      onSubmitted: (_) => _searchInvoice(),
                    ),

                    const SizedBox(height: 16),

                    // Past Returns Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RETURN HISTORY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        if (returnsList.isNotEmpty)
                          Text(
                            _searchQuery.isEmpty
                                ? '${returnsList.length} records'
                                : '${returnsList.where((r) {
                                    final q = _searchQuery;
                                    return r.invoiceId.toLowerCase().contains(q) || r.returnId.toLowerCase().contains(q) || r.reason.toLowerCase().contains(q) || r.items.any((item) => item.itemName.toLowerCase().contains(q) || item.partNo.toLowerCase().contains(q));
                                  }).length} of ${returnsList.length}',
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
                    if (!_isSearchingInvoice &&
                        state is ReturnLoading &&
                        returnsList.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (returnsList.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 36,
                          horizontal: 20,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(8),
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
                    else
                      ...() {
                        final filtered = returnsList.where((r) {
                          if (_searchQuery.isEmpty) return true;
                          final q = _searchQuery;
                          final matchInvoice = r.invoiceId
                              .toLowerCase()
                              .contains(q);
                          final matchReturn = r.returnId.toLowerCase().contains(
                            q,
                          );
                          final matchReason = r.reason.toLowerCase().contains(
                            q,
                          );
                          final matchItem = r.items.any(
                            (item) =>
                                item.itemName.toLowerCase().contains(q) ||
                                item.partNo.toLowerCase().contains(q),
                          );
                          return matchInvoice ||
                              matchReturn ||
                              matchReason ||
                              matchItem;
                        }).toList();

                        if (filtered.isEmpty) {
                          return [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 32,
                                horizontal: 20,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 36,
                                    color: isDark
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No matching return history',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF334155),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap the arrow button to fetch this invoice and process a return.',
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
                            ),
                          ];
                        }

                        return filtered.map((ret) {
                          return ReturnHistoryCard(
                            returnRecord: ret,
                            onPrintVoucher: () => _reprintVoucher(ret),
                          );
                        }).toList();
                      }(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
