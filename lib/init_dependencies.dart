import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gear_track/dependencies/inventory.dart';
import 'package:gear_track/dependencies/pos.dart';
import 'package:gear_track/dependencies/reports.dart';
import 'package:get_it/get_it.dart';

final serviceLocator = GetIt.instance;

Future<void> initDependencies() async {
  // External Core Services
  serviceLocator.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );

  // Feature Dependencies
  inventoryDependencies(serviceLocator);
  posDependencies(serviceLocator);
  reportsDependencies(serviceLocator);
}

