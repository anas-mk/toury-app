import 'package:flutter/foundation.dart';

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
      today: _readAmount(json['todayEarnings'] ?? json['today']),
      week: _readAmount(json['weekEarnings'] ?? json['week']),
      month: _readAmount(json['monthEarnings'] ?? json['month']),
      completedTrips: _readInt(
        json['completedTripsCount'] ?? json['completedTrips'],
      ),
      recentEarnings: (json['recentEarnings'] as List?)
              ?.whereType<Map>()
              .map((e) => EarningItemModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      chartData: (json['chartData'] as List?)
              ?.whereType<Map>()
              .map((e) => ChartDataPointModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  static double _readAmount(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? 0.0;
    return 0.0;
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
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
    debugPrint(
      '🔍 [EarningItemModel] Parsing JSON keys: ${json.keys.toList()}',
    );
    return EarningItemModel(
      bookingId: json['bookingId']?.toString() ?? '',
      amount: _readAmount(json),
      date: _readDate(json),
      travelerName: _readTravelerName(json),
    );
  }

  static double _readAmount(Map<String, dynamic> json) {
    const keys = [
      'amount',
      'payout',
      'earnings',
      'netAmount',
      'finalPayout',
      'estimatedPayout',
      'helperPayout',
    ];
    for (final key in keys) {
      final value = json[key];
      if (value is num && value > 0) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.trim());
        if (parsed != null && parsed > 0) return parsed;
      }
    }
    return 0.0;
  }

  static DateTime _readDate(Map<String, dynamic> json) {
    final raw = json['date'] ??
        json['completedAt'] ??
        json['earnedAt'] ??
        json['createdAt'];
    if (raw == null) return DateTime.now();
    return DateTime.tryParse(raw.toString()) ?? DateTime.now();
  }

  static String _readTravelerName(Map<String, dynamic> json) {
    final traveler = json['traveler'];
    if (traveler is Map) {
      final name = traveler['name'] ?? traveler['fullName'];
      if (name != null && name.toString().trim().isNotEmpty) {
        return name.toString();
      }
    }
    final direct = json['travelerName'];
    if (direct != null && direct.toString().trim().isNotEmpty) {
      return direct.toString();
    }
    return 'Traveler';
  }
}

class ChartDataPointModel extends ChartDataPoint {
  const ChartDataPointModel({
    required super.label,
    required super.value,
  });

  factory ChartDataPointModel.fromJson(Map<String, dynamic> json) {
    return ChartDataPointModel(
      label: json['label']?.toString() ?? '',
      value: HelperEarningsModel._readAmount(json['value']),
    );
  }
}
