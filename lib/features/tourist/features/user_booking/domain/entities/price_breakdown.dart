import 'package:equatable/equatable.dart';

/// Mirrors `BookingPriceBreakdown` from the backend.
///
/// All fields are nullable so we tolerate the backend tuning the breakdown
/// shape later. The only field we rely on for display is `total`.
class PriceBreakdown extends Equatable {
  final double? baseFare;
  final double? hourlyTotal;
  final double? carSurcharge;
  final double? distanceFee;
  final double? travelerSurcharge;
  final double? languageSurcharge;
  final double? discount;
  final double? tax;
  final double total;
  final String? currency;

  const PriceBreakdown({
    this.baseFare,
    this.hourlyTotal,
    this.carSurcharge,
    this.distanceFee,
    this.travelerSurcharge,
    this.languageSurcharge,
    this.discount,
    this.tax,
    required this.total,
    this.currency,
  });

  @override
  List<Object?> get props => [
        baseFare,
        hourlyTotal,
        carSurcharge,
        distanceFee,
        travelerSurcharge,
        languageSurcharge,
        discount,
        tax,
        total,
        currency,
      ];
}
