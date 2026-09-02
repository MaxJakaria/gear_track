import 'package:gear_track/feature/point_of_sale/data/repository/pos_repository_impl.dart';
import 'package:gear_track/feature/point_of_sale/data/sources/pos_remote_data_source.dart';
import 'package:gear_track/feature/point_of_sale/domain/repository/pos_repository.dart';
import 'package:gear_track/feature/point_of_sale/domain/usecases/add_sale.dart';
import 'package:gear_track/feature/point_of_sale/domain/usecases/checkout_cart.dart';
import 'package:gear_track/feature/point_of_sale/domain/usecases/get_product_sales.dart';
import 'package:gear_track/feature/point_of_sale/domain/usecases/get_sales.dart';
import 'package:gear_track/feature/point_of_sale/domain/usecases/save_invoice.dart';
import 'package:gear_track/feature/point_of_sale/presentation/bloc/pos_bloc.dart';
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
  sl.registerLazySingleton(() => CheckoutCart(sl()));
  sl.registerLazySingleton(() => GetSales(sl()));
  sl.registerLazySingleton(() => GetProductSales(sl()));
  sl.registerLazySingleton(() => SaveInvoice(sl()));

  // BLoC
  sl.registerFactory(
    () => PosBloc(
      addSale: sl(),
      checkoutCart: sl(),
      getSales: sl(),
      getProductSales: sl(),
      saveInvoice: sl(),
    ),
  );
}
