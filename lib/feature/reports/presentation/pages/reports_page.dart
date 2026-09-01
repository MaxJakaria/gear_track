import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

                    // Section 2: Executive 4 KPI Metric Cards Grid
                    KpiSummaryGrid(summary: report.summary),

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
