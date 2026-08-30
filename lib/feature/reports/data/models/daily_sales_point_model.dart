import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/daily_sales_point.dart';

class DailySalesPointModel extends DailySalesPoint {
  const DailySalesPointModel({
    required super.date,
    required super.label,
    required super.revenue,
  });

  factory DailySalesPointModel.fromMap(Map<String, dynamic> map) {
    return DailySalesPointModel(
      date: (map['date'] is Timestamp)
          ? (map['date'] as Timestamp).toDate()
          : (map['date'] != null
              ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now()
              : DateTime.now()),
      label: map['label'] ?? '',
      revenue: (map['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'label': label,
      'revenue': revenue,
    };
  }

  factory DailySalesPointModel.fromEntity(DailySalesPoint entity) {
    return DailySalesPointModel(
      date: entity.date,
      label: entity.label,
      revenue: entity.revenue,
    );
  }
}
