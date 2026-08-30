import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/reports_bloc.dart';
import '../widgets/daily_sales_trend_card.dart';
import '../widgets/embedded_calendar_card.dart';
import '../widgets/kpi_summary_grid.dart';
import '../widgets/monthly_profit_chart_card.dart';
import '../widgets/sales_table_card.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  @override
  void initState() {
    super.initState();
    context.read<ReportsBloc>().add(const FetchReportsEvent());
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reporting & Analytics',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: BlocBuilder<ReportsBloc, ReportsState>(
        builder: (context, state) {
          if (state is ReportsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ReportsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: Color(0xFFDC2626),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load analytics',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        context.read<ReportsBloc>().add(
                          const FetchReportsEvent(),
                        );
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is ReportsLoaded) {
            final activePeriod = state.activePeriod;
            final report = state.report;
            final customStart = state.customStartDate;
            final customEnd = state.customEndDate;

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
                    // Section 1: Embedded Interactive Calendar (Fixed in UI)
                    EmbeddedCalendarCard(
                      selectedStartDate: customStart,
                      selectedEndDate: customEnd,
                      onDateRangeChanged: _handleDateRangeChanged,
                      isLoading: state.isUpdating,
                    ),

                    const SizedBox(height: 18),

                    // Section 2: Executive 4 KPI Metric Cards Grid
                    KpiSummaryGrid(summary: report.summary),

                    const SizedBox(height: 20),

                    // Section 3: Visual Performance Trends (Horizontally Scrollable Charts)
                    // Chart 1: Daily Revenue Trend (Full Month / Scrollable)
                    DailySalesTrendCard(
                      trendPoints: report.dailySalesTrend,
                    ),

                    const SizedBox(height: 14),

                    // Chart 2: Monthly Sales vs Profit Comparison (12-Month / Scrollable)
                    MonthlyProfitChartCard(
                      monthlyData: report.monthlyProfitTrend,
                    ),

                    const SizedBox(height: 20),

                    // Section 4: Transactions Breakdown (Sales Table)
                    SalesTableCard(
                      salesRecords: report.salesRecords,
                      period: activePeriod,
                      startDate: customStart,
                      endDate: customEnd,
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
