import 'package:gear_track/feature/auth/data/repository/auth_repository_impl.dart';
import 'package:gear_track/feature/auth/data/sources/auth_remote_data_source.dart';
import 'package:gear_track/feature/auth/domain/repository/auth_repository.dart';
import 'package:gear_track/feature/auth/domain/usecases/check_auth_status.dart';
import 'package:gear_track/feature/auth/domain/usecases/complete_session_login.dart';
import 'package:gear_track/feature/auth/domain/usecases/send_sign_in_link.dart';
import 'package:gear_track/feature/auth/domain/usecases/sign_out.dart';
import 'package:gear_track/feature/auth/domain/usecases/watch_session_approval.dart';
import 'package:gear_track/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:get_it/get_it.dart';

void authDependencies(GetIt sl) {
  // Data Source
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firestore: sl(),
    ),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => SendSignInLink(sl()));
  sl.registerLazySingleton(() => WatchSessionApproval(sl()));
  sl.registerLazySingleton(() => CompleteSessionLogin(sl()));
  sl.registerLazySingleton(() => CheckAuthStatus(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));

  // BLoC
  sl.registerFactory(
    () => AuthBloc(
      sendSignInLink: sl(),
      watchSessionApproval: sl(),
      completeSessionLogin: sl(),
      checkAuthStatus: sl(),
      signOut: sl(),
    ),
  );
}
