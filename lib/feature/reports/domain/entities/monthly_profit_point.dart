import 'package:equatable/equatable.dart';

class MonthlyProfitPoint extends Equatable {
  final String monthLabel; // e.g. "Mar", "Apr", "May"
  final DateTime monthDate;
  final double sales;
  final double profit;

  const MonthlyProfitPoint({
    required this.monthLabel,
    required this.monthDate,
    required this.sales,
    required this.profit,
  });

  @override
  List<Object?> get props => [monthLabel, monthDate, sales, profit];
}
