import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/entities/cost_code_mapping.dart';
import 'package:gear_track/core/error/failure.dart';
import '../repository/settings_repository.dart';

class GetCostCodeMapping {
  final SettingsRepository repository;

  GetCostCodeMapping(this.repository);

  Future<Either<Failure, CostCodeMapping>> call() async {
    return await repository.getCostCodeMapping();
  }
}
