import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/entities/shop_settings.dart';
import 'package:gear_track/core/error/failure.dart';
import '../repository/settings_repository.dart';

class SaveShopSettings {
  final SettingsRepository repository;

  SaveShopSettings(this.repository);

  Future<Either<Failure, void>> call(ShopSettings settings) async {
    return await repository.saveShopSettings(settings);
  }
}
