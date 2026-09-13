import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/domain/usecases/get_shop_settings.dart';
import 'package:gear_track/core/entities/shop_settings.dart';
import 'package:gear_track/core/theme/app_colors.dart';
import 'package:gear_track/core/widgets/app_gradient_button.dart';
import 'package:gear_track/feature/point_of_sale/presentation/pages/pdf_preview_page.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';
import 'package:gear_track/feature/returns/domain/entities/return_entity.dart';
import 'package:gear_track/feature/returns/presentation/bloc/return_bloc.dart';
import 'package:gear_track/feature/returns/presentation/bloc/return_event.dart';
import 'package:gear_track/feature/returns/presentation/bloc/return_state.dart';
import 'package:gear_track/feature/returns/presentation/pages/process_return_page.dart';
import 'package:gear_track/feature/returns/presentation/widgets/process_return_tab.dart';
import 'package:gear_track/feature/returns/presentation/widgets/return_history_tab.dart';
import 'package:gear_track/feature/returns/utils/pdf_return_voucher_service.dart';
import 'package:gear_track/init_dependencies.dart';

/// Minimalist, high-end returns & refunds hub matching GearTrack's luxury UI.
/// Features a two-tab workflow:
/// 1. Process Return: Search sold invoices by Customer Name (partyName) or Invoice ID (invoiceId),
///    inspect products in expandable cards, and proceed to return.
/// 2. Return History: Database-paginated completed return records, metrics summary, and PDF receipt reprints.
class ReturnsPage extends StatefulWidget {
  const ReturnsPage({super.key});

  @override
  State<ReturnsPage> createState() => _ReturnsPageState();
}

class _ReturnsPageState extends State<ReturnsPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    final returnState = context.read<ReturnBloc>().state;
    if (returnState is! ReturnsLoadedSuccess) {
      context.read<ReturnBloc>().add(const FetchReturnsEvent(page: 1));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<ReturnBloc>().add(const ClearInvoiceSearchEvent());
  }

  void _searchInvoices() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _clearSearch();
      return;
    }
    context.read<ReturnBloc>().add(SearchInvoicesForReturnEvent(query));
  }

  Future<void> _openProcessReturn(
    InvoiceEntity invoice, {
    int? initialItemIndex,
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProcessReturnPage(
          invoice: invoice,
          initialItemIndex: initialItemIndex,
        ),
      ),
    );
    if (result == true && mounted) {
      context.read<ReturnBloc>().add(
        const FetchReturnsEvent(page: 1, forceRefresh: true),
      );
    }
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
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Returns & Refunds'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: _tabController.index == 0
                      ? AppGradientButton(
                          onPressed: () {},
                          label: 'Return',
                          height: 38,
                          borderRadius: 8,
                          fontSize: 13,
                        )
                      : Material(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _tabController.animateTo(0),
                            child: Container(
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: borderColor,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Return',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _tabController.index == 1
                      ? AppGradientButton(
                          onPressed: () {},
                          label: 'History',
                          height: 38,
                          borderRadius: 8,
                          fontSize: 13,
                        )
                      : Material(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _tabController.animateTo(1),
                            child: Container(
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: borderColor,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'History',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<ReturnBloc, ReturnState>(
          listener: (context, state) {
            if (state is ReturnFailure) {
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
            } else if (state is InvoiceLoadedForReturnSuccess) {
              _clearSearch();
              final invoice = state.invoice;
              context.read<ReturnBloc>().add(const ResetReturnStateEvent());
              _openProcessReturn(invoice);
            }
          },
          builder: (context, state) {
            return TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Process Return
                ProcessReturnTab(
                  searchController: _searchController,
                  state: state,
                  onSearch: _searchInvoices,
                  onClearSearch: _clearSearch,
                  onOpenProcessReturn: _openProcessReturn,
                  isDark: isDark,
                  cardBg: cardBg,
                  borderColor: borderColor,
                ),

                // Tab 2: Return History (Database-paginated)
                ReturnHistoryTab(
                  state: state,
                  onPrintVoucher: _reprintVoucher,
                  isDark: isDark,
                  cardBg: cardBg,
                  borderColor: borderColor,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
