import 'package:gear_track/feature/auth/data/repository/auth_repository_impl.dart';
import 'package:gear_track/feature/auth/data/sources/auth_remote_data_source.dart';
import 'package:gear_track/feature/auth/domain/repository/auth_repository.dart';
import 'package:gear_track/feature/auth/domain/usecases/check_auth_status.dart';
import 'package:gear_track/feature/auth/domain/usecases/login_with_email_password.dart';
import 'package:gear_track/feature/auth/domain/usecases/send_password_reset.dart';
import 'package:gear_track/feature/auth/domain/usecases/sign_out.dart';
import 'package:gear_track/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:get_it/get_it.dart';

void authDependencies(GetIt sl) {
  // Data Source
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => LoginWithEmailPassword(sl()));
  sl.registerLazySingleton(() => SendPasswordReset(sl()));
  sl.registerLazySingleton(() => CheckAuthStatus(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));

  // BLoC
  sl.registerFactory(
    () => AuthBloc(
      loginWithEmailPassword: sl(),
      sendPasswordReset: sl(),
      checkAuthStatus: sl(),
      signOut: sl(),
    ),
  );
}
