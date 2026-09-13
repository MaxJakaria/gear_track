import 'package:equatable/equatable.dart';

class DailySalesPoint extends Equatable {
  final DateTime date;
  final String label; // e.g. "08-17"
  final double revenue;
  final double profit;

  const DailySalesPoint({
    required this.date,
    required this.label,
    required this.revenue,
    this.profit = 0.0,
  });

  @override
  List<Object?> get props => [date, label, revenue, profit];
}
