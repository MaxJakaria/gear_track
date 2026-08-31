import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/entities/cost_code_mapping.dart';
import 'package:gear_track/core/entities/shop_settings.dart';
import 'package:gear_track/core/error/failure.dart';

abstract class SettingsRepository {
  Future<Either<Failure, CostCodeMapping>> getCostCodeMapping();
  Future<Either<Failure, void>> saveCostCodeMapping(CostCodeMapping mapping);

  Future<Either<Failure, ShopSettings>> getShopSettings();
  Future<Either<Failure, void>> saveShopSettings(ShopSettings settings);
}
