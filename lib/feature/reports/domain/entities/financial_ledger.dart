import 'package:equatable/equatable.dart';

class FinancialLedger extends Equatable {
  final double accumulatedRevenue;
  final double accumulatedProfit;
  final int accumulatedItemsSold;
  final double accumulatedInvestment;

  const FinancialLedger({
    this.accumulatedRevenue = 0.0,
    this.accumulatedProfit = 0.0,
    this.accumulatedItemsSold = 0,
    this.accumulatedInvestment = 0.0,
  });

  factory FinancialLedger.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const FinancialLedger();
    return FinancialLedger(
      accumulatedRevenue: (data['accumulatedRevenue'] as num?)?.toDouble() ?? 0.0,
      accumulatedProfit: (data['accumulatedProfit'] as num?)?.toDouble() ?? 0.0,
      accumulatedItemsSold: (data['accumulatedItemsSold'] as num?)?.toInt() ?? 0,
      accumulatedInvestment:
          (data['accumulatedInvestment'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accumulatedRevenue': accumulatedRevenue,
      'accumulatedProfit': accumulatedProfit,
      'accumulatedItemsSold': accumulatedItemsSold,
      'accumulatedInvestment': accumulatedInvestment,
    };
  }

  @override
  List<Object?> get props => [
        accumulatedRevenue,
        accumulatedProfit,
        accumulatedItemsSold,
        accumulatedInvestment,
      ];
}
