import 'package:flutter_test/flutter_test.dart';
import 'package:gear_track/feature/inventory/data/models/product_model.dart';
import 'package:gear_track/feature/point_of_sale/data/models/sale_model.dart';
import 'package:gear_track/feature/reports/data/repository/reports_repository_impl.dart';
import 'package:gear_track/feature/reports/data/sources/reports_remote_data_source.dart';
import 'package:gear_track/feature/reports/domain/entities/report_period.dart';

class MockReportsRemoteDataSource implements ReportsRemoteDataSource {
  final List<SaleModel> sales;
  final List<ProductModel> products;

  MockReportsRemoteDataSource({required this.sales, required this.products});

  @override
  Future<List<SaleModel>> getAllSales() async => sales;

  @override
  Future<List<ProductModel>> getAllProducts() async => products;
}

void main() {
  group('ReportsRepositoryImpl Aggregation Tests', () {
    final now = DateTime.now();

    final testProducts = [
      ProductModel(
        id: 'p1',
        entryDate: now,
        partNo: 'BRK-001',
        itemName: 'Brake Pad Set',
        model: 'Universal',
        costCode: '80',
        initialQuantity: 10,
        stockCount: 3, // <= 5 (Low Stock alert trigger)
      ),
      ProductModel(
        id: 'p2',
        entryDate: now,
        partNo: 'OIL-500',
        itemName: 'Engine Oil 5W30',
        model: 'Synthetic',
        costCode: '200',
        initialQuantity: 20,
        stockCount: 15, // > 5 (Normal stock)
      ),
    ];

    final testSales = [
      // Today sale
      SaleModel(
        id: 's1',
        productId: 'BRK-001',
        saleDate: now,
        itemName: 'Brake Pad Set',
        quantity: 2,
        sellPrice: 120.0,
        costCode: '80',
      ),
      // Sale earlier this month
      SaleModel(
        id: 's2',
        productId: 'OIL-500',
        saleDate: DateTime(now.year, now.month, 1, 10, 0),
        itemName: 'Engine Oil 5W30',
        quantity: 1,
        sellPrice: 300.0,
        costCode: '200',
      ),
    ];

    test('should calculate summary for Today correctly', () async {
      final mockSource = MockReportsRemoteDataSource(
        sales: testSales,
        products: testProducts,
      );
      final repo = ReportsRepositoryImpl(remoteDataSource: mockSource);

      final result = await repo.getAnalyticsReport(ReportPeriod.today);

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should succeed'),
        (report) {
          expect(report.period, ReportPeriod.today);
          // Today's sale: 2 * 120 = 240
          expect(report.summary.totalSales, 240.0);
          // Profit: (120 - 80) * 2 = 80
          expect(report.summary.totalProfit, 80.0);
          expect(report.summary.itemsSold, 2);
          // 1 product has stock <= 5
          expect(report.summary.lowStockAlerts, 1);
          expect(report.salesRecords.length, 1);
          expect(report.salesRecords.first.partNo, 'BRK-001');
          expect(report.salesRecords.first.model, 'Universal');
        },
      );
    });

    test('should calculate summary for This Month correctly', () async {
      final mockSource = MockReportsRemoteDataSource(
        sales: testSales,
        products: testProducts,
      );
      final repo = ReportsRepositoryImpl(remoteDataSource: mockSource);

      final result = await repo.getAnalyticsReport(ReportPeriod.thisMonth);

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should succeed'),
        (report) {
          expect(report.period, ReportPeriod.thisMonth);
          // Month sales: (2 * 120) + (1 * 300) = 540
          expect(report.summary.totalSales, 540.0);
          // Month profit: ((120 - 80) * 2) + ((300 - 200) * 1) = 80 + 100 = 180
          expect(report.summary.totalProfit, 180.0);
          expect(report.summary.itemsSold, 3);
          expect(report.summary.lowStockAlerts, 1);
          expect(report.salesRecords.length, 2);
        },
      );
    });

    test('should generate month daily trend and 12-month profit trend', () async {
      final mockSource = MockReportsRemoteDataSource(
        sales: testSales,
        products: testProducts,
      );
      final repo = ReportsRepositoryImpl(remoteDataSource: mockSource);

      final result = await repo.getAnalyticsReport(ReportPeriod.trends);

      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should succeed'),
        (report) {
          expect(report.dailySalesTrend.length, daysInMonth);
          expect(report.dailySalesTrend.first.label, '01');
          expect(report.monthlyProfitTrend.length, 12);
          // Today's daily point matches today's sales
          final todayPoint = report.dailySalesTrend.firstWhere(
            (p) => p.date.day == now.day,
          );
          expect(todayPoint.revenue, 240.0);
          expect(report.monthlyProfitTrend.last.sales, 540.0);
          expect(report.monthlyProfitTrend.last.profit, 180.0);
        },
      );
    });

    test('should calculate summary for Custom date range correctly', () async {
      final mockSource = MockReportsRemoteDataSource(
        sales: testSales,
        products: testProducts,
      );
      final repo = ReportsRepositoryImpl(remoteDataSource: mockSource);

      final customStart = DateTime(now.year, now.month, now.day);
      final customEnd = DateTime(now.year, now.month, now.day);

      final result = await repo.getAnalyticsReport(
        ReportPeriod.custom,
        startDate: customStart,
        endDate: customEnd,
      );

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should succeed'),
        (report) {
          expect(report.period, ReportPeriod.custom);
          expect(report.summary.totalSales, 240.0);
          expect(report.summary.totalProfit, 80.0);
          expect(report.summary.itemsSold, 2);
          expect(report.salesRecords.length, 1);
        },
      );
    });
  });
}
