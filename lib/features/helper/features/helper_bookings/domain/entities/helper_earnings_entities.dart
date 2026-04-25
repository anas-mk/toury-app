import 'package:equatable/equatable.dart';


class HelperEarnings extends Equatable {
  final double today;
  final double week;
  final double month;
  final int completedTrips;
  final List<EarningItem> recentEarnings;
  final List<ChartDataPoint> chartData;

  const HelperEarnings({
    required this.today,
    required this.week,
    required this.month,
    required this.completedTrips,
    required this.recentEarnings,
    required this.chartData,
  });

  @override
  List<Object?> get props => [today, week, month, completedTrips, recentEarnings, chartData];
}

class EarningItem extends Equatable {
  final String bookingId;
  final double amount;
  final DateTime date;
  final String travelerName;

  const EarningItem({
    required this.bookingId,
    required this.amount,
    required this.date,
    required this.travelerName,
  });

  @override
  List<Object?> get props => [bookingId, amount, date, travelerName];
}

class ChartDataPoint extends Equatable {
  final String label;
  final double value;

  const ChartDataPoint({
    required this.label,
    required this.value,
  });

  @override
  List<Object?> get props => [label, value];
}
