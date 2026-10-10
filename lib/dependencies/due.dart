import 'package:gear_track/feature/due_management/data/repository/due_repository_impl.dart';
import 'package:gear_track/feature/due_management/data/sources/due_remote_data_source.dart';
import 'package:gear_track/feature/due_management/domain/repository/due_repository.dart';
import 'package:gear_track/feature/due_management/presentation/bloc/due_bloc.dart';
import 'package:get_it/get_it.dart';

void dueDependencies(GetIt sl) {
  // Data Source
  sl.registerLazySingleton<DueRemoteDataSource>(
    () => DueRemoteDataSourceImpl(firestore: sl()),
  );

  // Repository
  sl.registerLazySingleton<DueRepository>(
    () => DueRepositoryImpl(remoteDataSource: sl()),
  );

  // BLoC
  sl.registerFactory(
    () => DueBloc(dueRepository: sl()),
  );
}
