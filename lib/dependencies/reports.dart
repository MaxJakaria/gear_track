import 'package:get_it/get_it.dart';
import '../feature/reports/data/repository/reports_repository_impl.dart';
import '../feature/reports/data/sources/reports_remote_data_source.dart';
import '../feature/reports/domain/repository/reports_repository.dart';
import '../feature/reports/domain/usecases/get_analytics_report.dart';
import '../feature/reports/presentation/bloc/reports_bloc.dart';

void reportsDependencies(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<ReportsRemoteDataSource>(
    () => ReportsRemoteDataSourceImpl(firestore: sl()),
  );

  // Repositories
  sl.registerLazySingleton<ReportsRepository>(
    () => ReportsRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetAnalyticsReport(sl()));

  // BLoC
  sl.registerFactory(
    () => ReportsBloc(
      getAnalyticsReport: sl(),
    ),
  );
}
