import 'package:gear_track/core/data/repository/settings_repository_impl.dart';
import 'package:gear_track/core/data/sources/settings_remote_data_source.dart';
import 'package:gear_track/core/domain/repository/settings_repository.dart';
import 'package:gear_track/core/domain/usecases/get_cost_code_mapping.dart';
import 'package:gear_track/core/domain/usecases/get_shop_settings.dart';
import 'package:gear_track/core/domain/usecases/save_cost_code_mapping.dart';
import 'package:gear_track/core/domain/usecases/save_shop_settings.dart';
import 'package:get_it/get_it.dart';

void settingsDependencies(GetIt sl) {
  // Data Source
  sl.registerLazySingleton<SettingsRemoteDataSource>(
    () => SettingsRemoteDataSourceImpl(firestore: sl()),
  );

  // Repository
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetCostCodeMapping(sl()));
  sl.registerLazySingleton(() => SaveCostCodeMapping(sl()));
  sl.registerLazySingleton(() => GetShopSettings(sl()));
  sl.registerLazySingleton(() => SaveShopSettings(sl()));
}
