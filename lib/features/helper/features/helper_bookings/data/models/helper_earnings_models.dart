import '../../domain/entities/helper_earnings_entities.dart';

class HelperEarningsModel extends HelperEarnings {
  const HelperEarningsModel({
    required super.today,
    required super.week,
    required super.month,
    required super.completedTrips,
    required super.recentEarnings,
    required super.chartData,
  });

  factory HelperEarningsModel.fromJson(Map<String, dynamic> json) {
    return HelperEarningsModel(
      today: (json['today'] as num?)?.toDouble() ?? 0.0,
      week: (json['week'] as num?)?.toDouble() ?? 0.0,
      month: (json['month'] as num?)?.toDouble() ?? 0.0,
      completedTrips: json['completedTrips'] ?? 0,
      recentEarnings: (json['recentEarnings'] as List?)
              ?.map((e) => EarningItemModel.fromJson(e))
              .toList() ??
          [],
      chartData: (json['chartData'] as List?)
              ?.map((e) => ChartDataPointModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class EarningItemModel extends EarningItem {
  const EarningItemModel({
    required super.bookingId,
    required super.amount,
    required super.date,
    required super.travelerName,
  });

  factory EarningItemModel.fromJson(Map<String, dynamic> json) {
    return EarningItemModel(
      bookingId: json['bookingId']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      travelerName: json['travelerName'] ?? 'Traveler',
    );
  }
}

class ChartDataPointModel extends ChartDataPoint {
  const ChartDataPointModel({
    required super.label,
    required super.value,
  });

  factory ChartDataPointModel.fromJson(Map<String, dynamic> json) {
    return ChartDataPointModel(
      label: json['label'] ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
