import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/returns/domain/entities/paginated_returns_entity.dart';
import 'package:gear_track/feature/returns/domain/repository/return_repository.dart';

class GetReturns {
  final ReturnRepository repository;

  GetReturns(this.repository);

  Future<Either<Failure, PaginatedReturnsEntity>> call({
    int page = 1,
    int pageSize = 10,
  }) async {
    return await repository.getReturns(page: page, pageSize: pageSize);
  }
}
