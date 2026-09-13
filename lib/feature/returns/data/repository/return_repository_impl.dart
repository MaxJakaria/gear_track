import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/error/failure.dart';
import 'package:gear_track/feature/receipt_verification/domain/entities/invoice_entity.dart';
import 'package:gear_track/feature/returns/data/models/return_model.dart';
import 'package:gear_track/feature/returns/data/sources/return_remote_data_source.dart';
import 'package:gear_track/feature/returns/domain/entities/paginated_returns_entity.dart';
import 'package:gear_track/feature/returns/domain/entities/return_entity.dart';
import 'package:gear_track/feature/returns/domain/repository/return_repository.dart';

class ReturnRepositoryImpl implements ReturnRepository {
  final ReturnRemoteDataSource remoteDataSource;

  ReturnRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ReturnEntity>> processReturn(
    ReturnEntity returnEntity,
  ) async {
    try {
      final model = returnEntity is ReturnModel
          ? returnEntity
          : ReturnModel(
              returnId: returnEntity.returnId,
              invoiceId: returnEntity.invoiceId,
              returnDate: returnEntity.returnDate,
              totalRefundAmount: returnEntity.totalRefundAmount,
              totalQuantity: returnEntity.totalQuantity,
              reason: returnEntity.reason,
              shopName: returnEntity.shopName,
              items: returnEntity.items.map((i) {
                if (i is ReturnItemModel) return i;
                return ReturnItemModel(
                  productId: i.productId,
                  itemName: i.itemName,
                  partNo: i.partNo,
                  quantity: i.quantity,
                  sellPrice: i.sellPrice,
                  costCode: i.costCode,
                  restock: i.restock,
                  reason: i.reason,
                );
              }).toList(),
            );

      final result = await remoteDataSource.processReturn(model);
      return Right(result);
    } on FirebaseException catch (e) {
      return Left(Failure(e.message ?? 'A database error occurred during return processing.'));
    } catch (e) {
      return Left(Failure('Failed to process return: $e'));
    }
  }

  @override
  Future<Either<Failure, PaginatedReturnsEntity>> getReturns({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await remoteDataSource.getReturns(
        page: page,
        pageSize: pageSize,
      );
      final entity = PaginatedReturnsEntity(
        returns: response.returns,
        totalCount: response.totalCount,
        totalRefundsAllTime: response.totalRefundsAllTime,
        totalItemsReturnedAllTime: response.totalItemsReturnedAllTime,
        currentPage: response.currentPage,
        totalPages: response.totalPages,
        hasMore: response.hasMore,
      );
      return Right(entity);
    } on FirebaseException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load returns list.'));
    } catch (e) {
      return Left(Failure('Failed to load returns: $e'));
    }
  }

  @override
  Future<Either<Failure, InvoiceEntity>> getInvoiceForReturn(
    String invoiceId,
  ) async {
    try {
      final invoice = await remoteDataSource.getInvoiceForReturn(invoiceId);
      return Right(invoice);
    } on FirebaseException catch (e) {
      return Left(Failure(e.message ?? 'Invoice not found.'));
    } catch (e) {
      return Left(Failure('Failed to fetch invoice: $e'));
    }
  }

  @override
  Future<Either<Failure, List<InvoiceEntity>>> searchInvoicesForReturn(
    String query,
  ) async {
    try {
      final invoices = await remoteDataSource.searchInvoicesForReturn(query);
      return Right(invoices);
    } on FirebaseException catch (e) {
      return Left(
        Failure(e.message ?? 'Database error while searching invoices.'),
      );
    } catch (e) {
      return Left(Failure('Failed to search invoices: $e'));
    }
  }
}
