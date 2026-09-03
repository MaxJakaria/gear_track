import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/domain/usecases/get_shop_settings.dart';
import 'package:gear_track/core/entities/shop_settings.dart';
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

class ReturnsPage extends StatefulWidget {
  const ReturnsPage({super.key});

  @override
  State<ReturnsPage> createState() => _ReturnsPageState();
}

class _ReturnsPageState extends State<ReturnsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ReturnBloc>().add(const FetchReturnsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchInvoice() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
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
        MaterialPageRoute(
          builder: (_) => PdfPreviewPage(pdfBytes: bytes),
        ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sales Returns & Refunds',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scan Receipt for Return',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReceiptVerificationPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Returns',
            onPressed: () {
              context.read<ReturnBloc>().add(const FetchReturnsEvent());
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<ReturnBloc, ReturnState>(
          listener: (context, state) {
            if (state is InvoiceLoadedForReturnSuccess) {
              _searchController.clear();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProcessReturnPage(invoice: state.invoice),
                ),
              ).then((_) {
                if (context.mounted) {
                  context.read<ReturnBloc>().add(const FetchReturnsEvent());
                }
              });
            } else if (state is ReturnFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage),
                  backgroundColor: const Color(0xFFD32F2F),
                  behavior: SnackBarBehavior.floating,
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

            return RefreshIndicator(
              onRefresh: () async {
                context.read<ReturnBloc>().add(const FetchReturnsEvent());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Metrics Banner
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xFF881337).withValues(alpha: 0.85),
                                  const Color(0xFF4C0519),
                                ]
                              : [
                                  const Color(0xFFFFF1F2),
                                  const Color(0xFFFFE4E6),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFE11D48).withValues(
                            alpha: isDark ? 0.4 : 0.5,
                          ),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TOTAL REFUNDED',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                      color: isDark
                                          ? const Color(0xFFFDA4AF)
                                          : const Color(0xFF9F1239),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    totalRefunds.toCurrency(),
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF881337),
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
                                  color: (isDark
                                          ? Colors.black
                                          : Colors.white)
                                      .withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${returnsList.length} Returns',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF881337),
                                      ),
                                    ),
                                    Text(
                                      '$totalItemsCount Items',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isDark
                                            ? const Color(0xFFFDA4AF)
                                            : const Color(0xFF9F1239),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Invoice Quick Search Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'START A NEW RETURN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter Invoice ID (e.g. GT-...)',
                                    isDense: true,
                                    prefixIcon: const Icon(Icons.search, size: 20),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onSubmitted: (_) => _searchInvoice(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: state is ReturnLoading
                                    ? null
                                    : _searchInvoice,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE11D48),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: state is ReturnLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Text(
                                        'Find',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Past Returns Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RETURNS HISTORY',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        if (returnsList.isNotEmpty)
                          Text(
                            '${returnsList.length} records',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Returns List or Empty View
                    if (state is ReturnLoading && returnsList.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (returnsList.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.assignment_turned_in_outlined,
                              size: 44,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No Returns Recorded Yet',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Returned items and refunds will show up here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...returnsList.map((ret) {
                        return ReturnHistoryCard(
                          returnRecord: ret,
                          onPrintVoucher: () => _reprintVoucher(ret),
                        );
                      }),
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
