import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/analytics_report.dart';
import '../entities/report_period.dart';
import '../repository/reports_repository.dart';

class GetAnalyticsReport {
  final ReportsRepository repository;

  GetAnalyticsReport(this.repository);

  Future<Either<Failure, AnalyticsReport>> call(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    return await repository.getAnalyticsReport(
      period,
      startDate: startDate,
      endDate: endDate,
      forceRefresh: forceRefresh,
    );
  }
}
