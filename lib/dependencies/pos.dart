import 'package:gear_track/feature/product_of_sales/data/repository/pos_repository_impl.dart';
import 'package:gear_track/feature/product_of_sales/data/sources/pos_remote_data_source.dart';
import 'package:gear_track/feature/product_of_sales/domain/repository/pos_repository.dart';
import 'package:gear_track/feature/product_of_sales/domain/usecases/add_sale.dart';
import 'package:gear_track/feature/product_of_sales/domain/usecases/get_product_sales.dart';
import 'package:gear_track/feature/product_of_sales/domain/usecases/get_sales.dart';
import 'package:gear_track/feature/product_of_sales/presentation/bloc/pos_bloc.dart';
import 'package:get_it/get_it.dart';

void posDependencies(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<PosRemoteDataSource>(
    () => PosRemoteDataSourceImpl(firestore: sl()),
  );

  // Repositories
  sl.registerLazySingleton<PosRepository>(
    () => PosRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => AddSale(sl()));
  sl.registerLazySingleton(() => GetSales(sl()));
  sl.registerLazySingleton(() => GetProductSales(sl()));

  // BLoC
  sl.registerFactory(
    () => PosBloc(
      addSale: sl(),
      getSales: sl(),
      getProductSales: sl(),
    ),
  );
}
