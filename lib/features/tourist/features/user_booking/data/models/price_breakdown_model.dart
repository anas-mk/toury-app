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
    double? d(List<String> keys) =>
        parseDoubleOrNull(pickJsonKey(json, keys));
    final totalRaw = pickJsonKey(json, [
      'finalPrice',
      'FinalPrice',
      'total',
      'Total',
      'subtotal',
      'Subtotal',
    ]);
    var total = parseDouble(totalRaw);
    if (total == 0) {
      final sub = parseDoubleOrNull(pickJsonKey(json, ['subtotal', 'Subtotal']));
      if (sub != null && sub > 0) total = sub;
    }
    return PriceBreakdownModel(
      baseFare: d(['baseFare', 'BaseFare', 'basePrice', 'BasePrice']),
      hourlyTotal: d([
        'hourlyTotal',
        'HourlyTotal',
        'durationCost',
        'DurationCost',
      ]),
      carSurcharge: d(['carSurcharge', 'CarSurcharge']),
      distanceFee: d(['distanceFee', 'DistanceFee', 'distanceCost', 'DistanceCost']),
      travelerSurcharge:
          d(['travelerSurcharge', 'TravelerSurcharge']),
      languageSurcharge:
          d(['languageSurcharge', 'LanguageSurcharge']),
      discount: d(['discount', 'Discount']),
      tax: d(['tax', 'Tax', 'instantSurcharge', 'InstantSurcharge']),
      total: total,
      currency: pickJsonKey(json, ['currency', 'Currency'])?.toString(),
    );
  }
}
