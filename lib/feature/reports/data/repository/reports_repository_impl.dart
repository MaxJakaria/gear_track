import 'package:fpdart/fpdart.dart';
import 'package:gear_track/core/domain/repository/settings_repository.dart';
import 'package:gear_track/core/entities/cost_code_mapping.dart';
import 'package:intl/intl.dart';
import 'package:gear_track/feature/reports/domain/entities/financial_ledger.dart';
import '../../../../core/error/failure.dart';
import '../../../../feature/inventory/data/models/product_model.dart';
import '../../../../feature/point_of_sale/data/models/sale_model.dart';
import '../../../../feature/returns/data/models/return_model.dart';
import '../../domain/entities/analytics_report.dart';
import '../../domain/entities/daily_sales_point.dart';
import '../../domain/entities/monthly_profit_point.dart';
import '../../domain/entities/report_period.dart';
import '../../domain/entities/sales_record_detail.dart';
import '../../domain/repository/reports_repository.dart';
import '../models/analytics_report_model.dart';
import '../models/analytics_summary_model.dart';
import '../sources/reports_remote_data_source.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsRemoteDataSource remoteDataSource;
  final SettingsRepository settingsRepository;

  List<SaleModel>? _cachedSales;
  List<ProductModel>? _cachedProducts;
  List<ReturnModel>? _cachedReturns;
  CostCodeMapping? _cachedCostCodeMapping;
  FinancialLedger? _cachedFinancialLedger;

  ReportsRepositoryImpl({
    required this.remoteDataSource,
    required this.settingsRepository,
  });

  @override
  Future<Either<Failure, AnalyticsReport>> getAnalyticsReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    try {
      final List<SaleModel> allSales;
      final List<ProductModel> allProducts;
      final List<ReturnModel> allReturns;
      final CostCodeMapping costCodeMapping;
      final FinancialLedger financialLedger;

      if (!forceRefresh &&
          _cachedSales != null &&
          _cachedProducts != null &&
          _cachedReturns != null &&
          _cachedCostCodeMapping != null &&
          _cachedFinancialLedger != null) {
        allSales = _cachedSales!;
        allProducts = _cachedProducts!;
        allReturns = _cachedReturns!;
        costCodeMapping = _cachedCostCodeMapping!;
        financialLedger = _cachedFinancialLedger!;
      } else {
        final results = await Future.wait([
          remoteDataSource.getAllSales(),
          remoteDataSource.getAllProducts(),
          settingsRepository.getCostCodeMapping(),
          remoteDataSource.getAllReturns(),
          remoteDataSource.getFinancialLedger(),
        ]);

        allSales = results[0] as List<SaleModel>;
        allProducts = results[1] as List<ProductModel>;
        final costCodeMappingEither =
            results[2] as Either<Failure, CostCodeMapping>;
        costCodeMapping = costCodeMappingEither.getOrElse(
          (_) => CostCodeMapping.defaultMapping(),
        );
        allReturns = results[3] as List<ReturnModel>;
        financialLedger = results[4] as FinancialLedger;

        _cachedSales = allSales;
        _cachedProducts = allProducts;
        _cachedReturns = allReturns;
        _cachedCostCodeMapping = costCodeMapping;
        _cachedFinancialLedger = financialLedger;
      }

      final now = DateTime.now();

      // 1. Build product lookup map (partNo -> product info)
      final Map<String, ProductModel> productMap = {};
      final Map<String, int> productStockCountMap = {};

      for (final prod in allProducts) {
        final key = prod.partNo.isNotEmpty ? prod.partNo : prod.id;
        if (!productMap.containsKey(key) || prod.model.isNotEmpty) {
          productMap[key] = prod;
        }
        productStockCountMap[key] =
            (productStockCountMap[key] ?? 0) + prod.stockCount;
      }

      // 2. Compute Low Stock Alerts & Total Investment (in-stock items value)
      int lowStockCount = 0;
      for (final totalStock in productStockCountMap.values) {
        if (totalStock <= 5) {
          lowStockCount++;
        }
      }

      // Baseline investment from permanently archived cleared catalog + active in-stock items
      double totalInvestment = financialLedger.accumulatedInvestment;
      for (final prod in allProducts) {
        if (prod.stockCount > 0) {
          final costPerUnit = costCodeMapping.decode(prod.costCode);
          totalInvestment += prod.stockCount * costPerUnit;
        }
      }

      // 3. Filter sales based on period for Summary & Table
      final List<SaleModel> periodSales;
      DateTime? effectiveStart;
      DateTime? effectiveEnd;

      if (period == ReportPeriod.today) {
        periodSales = allSales.where((s) {
          final d = s.saleDate;
          return d.year == now.year && d.month == now.month && d.day == now.day;
        }).toList();
      } else if (period == ReportPeriod.thisMonth) {
        periodSales = allSales.where((s) {
          final d = s.saleDate;
          return d.year == now.year && d.month == now.month;
        }).toList();
      } else if (period == ReportPeriod.custom &&
          startDate != null &&
          endDate != null) {
        effectiveStart =
            DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
        effectiveEnd =
            DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);

        periodSales = allSales.where((s) {
          return !s.saleDate.isBefore(effectiveStart!) &&
              !s.saleDate.isAfter(effectiveEnd!);
        }).toList();
      } else {
        // Overall period: all sales
        periodSales = allSales;
      }

      // Filter returns for active period
      final List<ReturnModel> periodReturns;
      if (period == ReportPeriod.today) {
        periodReturns = allReturns.where((r) {
          final d = r.returnDate;
          return d.year == now.year && d.month == now.month && d.day == now.day;
        }).toList();
      } else if (period == ReportPeriod.thisMonth) {
        periodReturns = allReturns.where((r) {
          final d = r.returnDate;
          return d.year == now.year && d.month == now.month;
        }).toList();
      } else if (period == ReportPeriod.custom &&
          effectiveStart != null &&
          effectiveEnd != null) {
        periodReturns = allReturns.where((r) {
          return !r.returnDate.isBefore(effectiveStart!) &&
              !r.returnDate.isAfter(effectiveEnd!);
        }).toList();
      } else {
        periodReturns = allReturns;
      }

      // 4. Calculate KPI metrics for the current active period
      double totalSales = 0.0;
      double totalProfit = 0.0;
      int itemsSold = 0;

      final List<SalesRecordDetail> salesRecords = [];

      for (final sale in periodSales) {
        final revenue = sale.sellPrice * sale.quantity;
        final costPerUnit = costCodeMapping.decode(sale.costCode);
        final double profitPerUnit;
        if (costPerUnit > 0) {
          profitPerUnit = sale.sellPrice - costPerUnit;
        } else {
          profitPerUnit = sale.sellPrice * 0.30;
        }
        final profit = profitPerUnit * sale.quantity;

        totalSales += revenue;
        totalProfit += profit;
        itemsSold += sale.quantity;

        // Enrich product details
        final matchedProduct = productMap[sale.productId];
        final partNo = matchedProduct?.partNo ?? sale.productId;
        final model = matchedProduct?.model ?? '';

        salesRecords.add(
          SalesRecordDetail(
            id: sale.id,
            saleDate: sale.saleDate,
            partNo: partNo,
            itemName: sale.itemName,
            model: model,
            itemsSold: sale.quantity,
            sellPrice: sale.sellPrice,
            costCode: sale.costCode,
          ),
        );
      }

      // Deduct returns (Selling Price / Revenue, Profit, and Quantity)
      double totalReturnRefund = 0.0;
      double totalReturnProfit = 0.0;
      int totalReturnQuantity = 0;

      for (final ret in periodReturns) {
        totalReturnRefund += ret.totalRefundAmount;
        totalReturnQuantity += ret.totalQuantity;

        for (final item in ret.items) {
          final costPerUnit = costCodeMapping.decode(item.costCode);
          final double profitPerUnit;
          if (costPerUnit > 0) {
            profitPerUnit = item.sellPrice - costPerUnit;
          } else {
            profitPerUnit = item.sellPrice * 0.30;
          }
          totalReturnProfit += profitPerUnit * item.quantity;
        }
      }

      totalSales = (totalSales - totalReturnRefund).clamp(0.0, double.infinity);
      totalProfit = totalProfit - totalReturnProfit;
      itemsSold = (itemsSold - totalReturnQuantity).clamp(0, 9999999);

      // Permanently add baseline revenue & profit from financial ledger (preserved across history clears)
      totalSales += financialLedger.accumulatedRevenue;
      totalProfit += financialLedger.accumulatedProfit;
      itemsSold += financialLedger.accumulatedItemsSold;

      // Sort sales records descending by date
      salesRecords.sort((a, b) => b.saleDate.compareTo(a.saleDate));

      // 5. Generate Daily Sales Trend (From Day 01 of Month to End of Month / Range)
      final List<DailySalesPoint> dailySalesTrend = [];

      if (period == ReportPeriod.custom &&
          effectiveStart != null &&
          effectiveEnd != null) {
        final totalDays = effectiveEnd.difference(effectiveStart).inDays + 1;
        final daysToGenerate = totalDays.clamp(1, 60);

        for (int i = 0; i < daysToGenerate; i++) {
          final targetDay = effectiveStart.add(Duration(days: i));

          final daySales = allSales.where((s) {
            final d = s.saleDate;
            return d.year == targetDay.year &&
                d.month == targetDay.month &&
                d.day == targetDay.day;
          });

          final dayGross = daySales.fold<double>(
            0.0,
            (acc, s) => acc + (s.sellPrice * s.quantity),
          );

          final dayReturns = allReturns.where((r) {
            final d = r.returnDate;
            return d.year == targetDay.year &&
                d.month == targetDay.month &&
                d.day == targetDay.day;
          });
          final dayRefund = dayReturns.fold<double>(
            0.0,
            (acc, r) => acc + r.totalRefundAmount,
          );

          double dayGrossProfit = 0.0;
          for (final s in daySales) {
            final costPerUnit = costCodeMapping.decode(s.costCode);
            final double profitPerUnit;
            if (costPerUnit > 0) {
              profitPerUnit = s.sellPrice - costPerUnit;
            } else {
              profitPerUnit = s.sellPrice * 0.30;
            }
            dayGrossProfit += profitPerUnit * s.quantity;
          }

          double dayReturnProfit = 0.0;
          for (final r in dayReturns) {
            for (final item in r.items) {
              final costPerUnit = costCodeMapping.decode(item.costCode);
              final double profitPerUnit;
              if (costPerUnit > 0) {
                profitPerUnit = item.sellPrice - costPerUnit;
              } else {
                profitPerUnit = item.sellPrice * 0.30;
              }
              dayReturnProfit += profitPerUnit * item.quantity;
            }
          }

          dailySalesTrend.add(
            DailySalesPoint(
              date: targetDay,
              label: targetDay.day.toString().padLeft(2, '0'),
              revenue: (dayGross - dayRefund).clamp(0.0, double.infinity),
              profit: dayGrossProfit - dayReturnProfit,
            ),
          );
        }
      } else {
        // Complete current month from Day 01 to the last day of the month
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

        for (int day = 1; day <= daysInMonth; day++) {
          final targetDay = DateTime(now.year, now.month, day);
          final daySales = allSales.where((s) {
            final d = s.saleDate;
            return d.year == targetDay.year &&
                d.month == targetDay.month &&
                d.day == targetDay.day;
          });

          final dayGross = daySales.fold<double>(
            0.0,
            (acc, s) => acc + (s.sellPrice * s.quantity),
          );

          final dayReturns = allReturns.where((r) {
            final d = r.returnDate;
            return d.year == targetDay.year &&
                d.month == targetDay.month &&
                d.day == targetDay.day;
          });
          final dayRefund = dayReturns.fold<double>(
            0.0,
            (acc, r) => acc + r.totalRefundAmount,
          );

          double dayGrossProfit = 0.0;
          for (final s in daySales) {
            final costPerUnit = costCodeMapping.decode(s.costCode);
            final double profitPerUnit;
            if (costPerUnit > 0) {
              profitPerUnit = s.sellPrice - costPerUnit;
            } else {
              profitPerUnit = s.sellPrice * 0.30;
            }
            dayGrossProfit += profitPerUnit * s.quantity;
          }

          double dayReturnProfit = 0.0;
          for (final r in dayReturns) {
            for (final item in r.items) {
              final costPerUnit = costCodeMapping.decode(item.costCode);
              final double profitPerUnit;
              if (costPerUnit > 0) {
                profitPerUnit = item.sellPrice - costPerUnit;
              } else {
                profitPerUnit = item.sellPrice * 0.30;
              }
              dayReturnProfit += profitPerUnit * item.quantity;
            }
          }

          dailySalesTrend.add(
            DailySalesPoint(
              date: targetDay,
              label: day.toString().padLeft(2, '0'),
              revenue: (dayGross - dayRefund).clamp(0.0, double.infinity),
              profit: dayGrossProfit - dayReturnProfit,
            ),
          );
        }
      }

      // 6. Generate 12-Month (Full 1 Year: Jan-Dec) Monthly Sales vs. Profit Trend based on Selected Year
      final List<MonthlyProfitPoint> monthlyProfitTrend = [];
      final monthFormat = DateFormat('MMM');
      final int targetYear =
          startDate?.year ?? (effectiveStart?.year ?? now.year);

      for (int m = 1; m <= 12; m++) {
        final targetMonthDate = DateTime(targetYear, m, 1);
        final targetMonth = m;

        final monthSalesList = allSales.where((s) {
          final d = s.saleDate;
          return d.year == targetYear && d.month == targetMonth;
        });

        double mSales = 0.0;
        double mProfit = 0.0;

        for (final s in monthSalesList) {
          final rev = s.sellPrice * s.quantity;
          final cost = costCodeMapping.decode(s.costCode);
          final double profitUnit;
          if (cost > 0) {
            profitUnit = s.sellPrice - cost;
          } else {
            profitUnit = s.sellPrice * 0.30;
          }
          mSales += rev;
          mProfit += profitUnit * s.quantity;
        }

        // Deduct monthly returns
        final monthReturnsList = allReturns.where((r) {
          final d = r.returnDate;
          return d.year == targetYear && d.month == targetMonth;
        });

        for (final ret in monthReturnsList) {
          mSales -= ret.totalRefundAmount;
          for (final item in ret.items) {
            final cost = costCodeMapping.decode(item.costCode);
            final double profitUnit;
            if (cost > 0) {
              profitUnit = item.sellPrice - cost;
            } else {
              profitUnit = item.sellPrice * 0.30;
            }
            mProfit -= profitUnit * item.quantity;
          }
        }

        monthlyProfitTrend.add(
          MonthlyProfitPoint(
            monthLabel: monthFormat.format(targetMonthDate),
            monthDate: targetMonthDate,
            sales: mSales.clamp(0.0, double.infinity),
            profit: mProfit,
          ),
        );
      }

      final reportModel = AnalyticsReportModel(
        period: period,
        startDate: effectiveStart,
        endDate: effectiveEnd,
        summary: AnalyticsSummaryModel(
          totalSales: totalSales,
          totalProfit: totalProfit,
          itemsSold: itemsSold,
          lowStockAlerts: lowStockCount,
          totalInvestment: totalInvestment,
        ),
        salesRecords: salesRecords,
        dailySalesTrend: dailySalesTrend,
        monthlyProfitTrend: monthlyProfitTrend,
      );

      return Right(reportModel);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}
