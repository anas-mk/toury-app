import '../../domain/entities/price_breakdown.dart';
import 'json_helpers.dart';

class PriceBreakdownModel extends PriceBreakdown {
  const PriceBreakdownModel({
    super.baseFare,
    super.hourlyTotal,
    super.carSurcharge,
    super.distanceFee,
    super.travelerSurcharge,
    super.languageSurcharge,
    super.discount,
    super.tax,
    required super.total,
    super.currency,
  });

  factory PriceBreakdownModel.fromJson(Map<String, dynamic> json) {
    return PriceBreakdownModel(
      baseFare: parseDoubleOrNull(json['baseFare']),
      hourlyTotal: parseDoubleOrNull(json['hourlyTotal']),
      carSurcharge: parseDoubleOrNull(json['carSurcharge']),
      distanceFee: parseDoubleOrNull(json['distanceFee']),
      travelerSurcharge: parseDoubleOrNull(json['travelerSurcharge']),
      languageSurcharge: parseDoubleOrNull(json['languageSurcharge']),
      discount: parseDoubleOrNull(json['discount']),
      tax: parseDoubleOrNull(json['tax']),
      total: parseDouble(json['total']),
      currency: json['currency']?.toString(),
    );
  }
}
