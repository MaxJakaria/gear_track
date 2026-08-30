import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/analytics_report.dart';
import '../entities/report_period.dart';

abstract class ReportsRepository {
  Future<Either<Failure, AnalyticsReport>> getAnalyticsReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  });
}
