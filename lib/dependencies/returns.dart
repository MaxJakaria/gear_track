import 'package:gear_track/feature/returns/data/repository/return_repository_impl.dart';
import 'package:gear_track/feature/returns/data/sources/return_remote_data_source.dart';
import 'package:gear_track/feature/returns/domain/repository/return_repository.dart';
import 'package:gear_track/feature/returns/domain/usecases/get_invoice_for_return.dart';
import 'package:gear_track/feature/returns/domain/usecases/get_returns.dart';
import 'package:gear_track/feature/returns/domain/usecases/process_return.dart';
import 'package:gear_track/feature/returns/presentation/bloc/return_bloc.dart';
import 'package:get_it/get_it.dart';

void returnsDependencies(GetIt sl) {
  // Data Source
  sl.registerLazySingleton<ReturnRemoteDataSource>(
    () => ReturnRemoteDataSourceImpl(firestore: sl()),
  );

  // Repository
  sl.registerLazySingleton<ReturnRepository>(
    () => ReturnRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => ProcessReturn(sl()));
  sl.registerLazySingleton(() => GetReturns(sl()));
  sl.registerLazySingleton(() => GetInvoiceForReturn(sl()));

  // BLoC
  sl.registerFactory(
    () => ReturnBloc(
      processReturn: sl(),
      getReturns: sl(),
      getInvoiceForReturn: sl(),
    ),
  );
}
