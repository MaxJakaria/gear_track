import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/entities/cost_code_mapping.dart';
import 'package:gear_track/core/entities/shop_settings.dart';
import 'package:gear_track/core/error/failure.dart';
import '../../domain/repository/settings_repository.dart';
import '../sources/settings_remote_data_source.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource remoteDataSource;

  SettingsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, CostCodeMapping>> getCostCodeMapping() async {
    try {
      final mapping = await remoteDataSource.getCostCodeMapping();
      return Right(mapping);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveCostCodeMapping(
    CostCodeMapping mapping,
  ) async {
    try {
      await remoteDataSource.saveCostCodeMapping(mapping);
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ShopSettings>> getShopSettings() async {
    try {
      final settings = await remoteDataSource.getShopSettings();
      return Right(settings);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveShopSettings(
    ShopSettings settings,
  ) async {
    try {
      await remoteDataSource.saveShopSettings(settings);
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}
