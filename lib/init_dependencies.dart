import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gear_track/dependencies/auth.dart';
import 'package:gear_track/dependencies/inventory.dart';
import 'package:gear_track/dependencies/pos.dart';
import 'package:gear_track/dependencies/receipt_verification.dart';
import 'package:gear_track/dependencies/reports.dart';
import 'package:gear_track/dependencies/returns.dart';
import 'package:gear_track/dependencies/settings.dart';
import 'package:gear_track/feature/database_maintenance/data/sources/database_maintenance_remote_data_source.dart';
import 'package:get_it/get_it.dart';

final serviceLocator = GetIt.instance;

Future<void> initDependencies() async {
  // External Core Services with aggressive local caching
  serviceLocator.registerLazySingleton<FirebaseFirestore>(() {
    final firestore = FirebaseFirestore.instance;
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    return firestore;
  });

  // Settings & App Configuration
  settingsDependencies(serviceLocator);

  // Feature Dependencies
  authDependencies(serviceLocator);
  inventoryDependencies(serviceLocator);
  posDependencies(serviceLocator);
  receiptVerificationDependencies(serviceLocator);
  reportsDependencies(serviceLocator);
  returnsDependencies(serviceLocator);

  // Database Maintenance Service
  serviceLocator.registerLazySingleton<DatabaseMaintenanceRemoteDataSource>(
    () => DatabaseMaintenanceRemoteDataSourceImpl(serviceLocator()),
  );
}

