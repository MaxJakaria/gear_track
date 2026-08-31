import 'package:gear_track/feature/receipt_verification/data/repository/receipt_verification_repository_impl.dart';
import 'package:gear_track/feature/receipt_verification/data/sources/receipt_verification_remote_data_source.dart';
import 'package:gear_track/feature/receipt_verification/domain/repository/receipt_verification_repository.dart';
import 'package:gear_track/feature/receipt_verification/domain/usecases/verify_receipt.dart';
import 'package:gear_track/feature/receipt_verification/presentation/bloc/receipt_verification_bloc.dart';
import 'package:get_it/get_it.dart';

void receiptVerificationDependencies(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<ReceiptVerificationRemoteDataSource>(
    () => ReceiptVerificationRemoteDataSourceImpl(firestore: sl()),
  );

  // Repositories
  sl.registerLazySingleton<ReceiptVerificationRepository>(
    () => ReceiptVerificationRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => VerifyReceipt(sl()));

  // BLoC
  sl.registerFactory(
    () => ReceiptVerificationBloc(
      verifyReceipt: sl(),
    ),
  );
}
