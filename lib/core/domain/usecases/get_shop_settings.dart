import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/entities/shop_settings.dart';
import 'package:gear_track/core/error/failure.dart';
import '../repository/settings_repository.dart';

class GetShopSettings {
  final SettingsRepository repository;

  GetShopSettings(this.repository);

  Future<Either<Failure, ShopSettings>> call() async {
    return await repository.getShopSettings();
  }
}
