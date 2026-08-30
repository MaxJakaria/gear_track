import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/monthly_profit_point.dart';

class MonthlyProfitPointModel extends MonthlyProfitPoint {
  const MonthlyProfitPointModel({
    required super.monthLabel,
    required super.monthDate,
    required super.sales,
    required super.profit,
  });

  factory MonthlyProfitPointModel.fromMap(Map<String, dynamic> map) {
    return MonthlyProfitPointModel(
      monthLabel: map['monthLabel'] ?? '',
      monthDate: (map['monthDate'] is Timestamp)
          ? (map['monthDate'] as Timestamp).toDate()
          : (map['monthDate'] != null
              ? DateTime.tryParse(map['monthDate'].toString()) ?? DateTime.now()
              : DateTime.now()),
      sales: (map['sales'] as num?)?.toDouble() ?? 0.0,
      profit: (map['profit'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'monthLabel': monthLabel,
      'monthDate': Timestamp.fromDate(monthDate),
      'sales': sales,
      'profit': profit,
    };
  }

  factory MonthlyProfitPointModel.fromEntity(MonthlyProfitPoint entity) {
    return MonthlyProfitPointModel(
      monthLabel: entity.monthLabel,
      monthDate: entity.monthDate,
      sales: entity.sales,
      profit: entity.profit,
    );
  }
}
