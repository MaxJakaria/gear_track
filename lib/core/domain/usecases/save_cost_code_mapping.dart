import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/entities/cost_code_mapping.dart';
import 'package:gear_track/core/error/failure.dart';
import '../repository/settings_repository.dart';

class SaveCostCodeMapping {
  final SettingsRepository repository;

  SaveCostCodeMapping(this.repository);

  Future<Either<Failure, void>> call(CostCodeMapping mapping) async {
    return await repository.saveCostCodeMapping(mapping);
  }
}
