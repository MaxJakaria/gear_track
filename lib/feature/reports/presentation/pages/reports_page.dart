import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:gear_track/init_dependencies.dart';
import 'package:gear_track/core/domain/usecases/get_shop_settings.dart';
import 'package:gear_track/core/entities/shop_settings.dart';
import 'package:gear_track/feature/reports/domain/entities/analytics_report.dart';
import 'package:gear_track/feature/reports/utils/pdf_report_service.dart';
import '../bloc/reports_bloc.dart';
import '../widgets/embedded_calendar_card.dart';
import '../widgets/kpi_summary_grid.dart';
import '../widgets/performance_trends_section.dart';
import '../widgets/reports_error_view.dart';
import '../widgets/sales_table_card.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    final reportsState = context.read<ReportsBloc>().state;
    if (reportsState is! ReportsLoaded) {
      context.read<ReportsBloc>().add(const FetchReportsEvent());
    }
  }

  void _handleDateRangeChanged(DateTime? start, DateTime? end) {
    if (start == null && end == null) {
      context.read<ReportsBloc>().add(const ClearDateFilterEvent());
    } else if (start != null) {
      context.read<ReportsBloc>().add(
        SelectCustomDateRangeEvent(startDate: start, endDate: end ?? start),
      );
    }
  }

  Future<void> _exportPdfReport(
    AnalyticsReport report,
    ReportsLoaded state,
  ) async {
    if (_isGeneratingPdf) return;

    setState(() => _isGeneratingPdf = true);

    ShopSettings shopSettings = const ShopSettings();
    try {
      final getShopSettings = serviceLocator<GetShopSettings>();
      final result = await getShopSettings().timeout(const Duration(seconds: 2));
      result.fold((_) {}, (settings) => shopSettings = settings);
    } catch (_) {}

    try {
      final pdfBytes = await PdfReportService.generateReportPdf(
        report: report,
        shopSettings: shopSettings,
        startDate: state.customStartDate,
        endDate: state.customEndDate,
        isFilterApplied: state.customStartDate != null,
      );

      if (!mounted) return;
      setState(() => _isGeneratingPdf = false);

      final String filename;
      if (state.customStartDate != null && state.customEndDate != null) {
        final start = DateFormat('yyyyMMdd').format(state.customStartDate!);
        final end = DateFormat('yyyyMMdd').format(state.customEndDate!);
        filename = 'geartrack_report_${start}_$end.pdf';
      } else if (state.customStartDate != null) {
        final start = DateFormat('yyyyMMdd').format(state.customStartDate!);
        filename = 'geartrack_report_$start.pdf';
      } else {
        final nowStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
        filename = 'geartrack_all_time_report_$nowStr.pdf';
      }

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: filename,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGeneratingPdf = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate PDF: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reporting & Analytics',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          BlocBuilder<ReportsBloc, ReportsState>(
            builder: (context, state) {
              if (state is ReportsLoaded) {
                return _isGeneratingPdf
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.picture_as_pdf_rounded),
                        tooltip: 'Export PDF Report',
                        onPressed: () => _exportPdfReport(
                          state.report,
                          state,
                        ),
                      );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocBuilder<ReportsBloc, ReportsState>(
        builder: (context, state) {
          if (state is ReportsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ReportsError) {
            return ReportsErrorView(
              message: state.message,
              onRetry: () {
                context.read<ReportsBloc>().add(const FetchReportsEvent());
              },
            );
          }

          if (state is ReportsLoaded) {
            final report = state.report;

            return RefreshIndicator(
              onRefresh: () async {
                context.read<ReportsBloc>().add(const RefreshReportsEvent());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 14.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Embedded Interactive Calendar
                    EmbeddedCalendarCard(
                      selectedStartDate: state.customStartDate,
                      selectedEndDate: state.customEndDate,
                      onDateRangeChanged: _handleDateRangeChanged,
                      isLoading: state.isUpdating,
                    ),

                    const SizedBox(height: 18),

                    // Section 2: Executive KPI Metric Cards Grid
                    KpiSummaryGrid(
                      summary: report.summary,
                      showInvestment: state.customStartDate == null,
                    ),

                    const SizedBox(height: 20),

                    // Section 3: Visual Performance Trends (Daily & Monthly Chart Switcher)
                    PerformanceTrendsSection(
                      dailySalesTrend: report.dailySalesTrend,
                      monthlyProfitTrend: report.monthlyProfitTrend,
                    ),

                    const SizedBox(height: 20),

                    // Section 4: Transactions Breakdown (Sales Table)
                    SalesTableCard(
                      salesRecords: report.salesRecords,
                      period: state.activePeriod,
                      startDate: state.customStartDate,
                      endDate: state.customEndDate,
                    ),

                    const SizedBox(height: 36),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
