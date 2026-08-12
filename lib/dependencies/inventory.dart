import 'package:gear_track/feature/inventory/data/repository/inventory_repository_impl.dart';
import 'package:gear_track/feature/inventory/data/sources/inventory_remote_data_source.dart';
import 'package:gear_track/feature/inventory/domain/repository/inventory_repository.dart';
import 'package:gear_track/feature/inventory/domain/usecases/add_product.dart';
import 'package:gear_track/feature/inventory/domain/usecases/delete_product.dart';
import 'package:gear_track/feature/inventory/domain/usecases/get_product.dart';
import 'package:gear_track/feature/inventory/domain/usecases/update_product.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:get_it/get_it.dart';

void inventoryDependencies(GetIt sl) {
  // Data sources
  sl.registerLazySingleton<InventoryRemoteDataSource>(
    () => InventoryRemoteDataSourceImpl(firestore: sl()),
  );

  // Repositories
  sl.registerLazySingleton<InventoryRepository>(
    () => InventoryRepositoryImpl(remoteDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => AddProduct(sl()));
  sl.registerLazySingleton(() => GetProducts(sl()));
  sl.registerLazySingleton(() => UpdateProduct(sl()));
  sl.registerLazySingleton(() => DeleteProduct(sl()));

  // BLoCs
  sl.registerFactory(
    () => InventoryBloc(
      addProduct: sl(),
      getProducts: sl(),
      updateProduct: sl(),
      deleteProduct: sl(),
    ),
  );
}


