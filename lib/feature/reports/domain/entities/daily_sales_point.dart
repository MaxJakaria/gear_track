import 'package:equatable/equatable.dart';

class DailySalesPoint extends Equatable {
  final DateTime date;
  final String label; // e.g. "08-17"
  final double revenue;

  const DailySalesPoint({
    required this.date,
    required this.label,
    required this.revenue,
  });

  @override
  List<Object?> get props => [date, label, revenue];
}
