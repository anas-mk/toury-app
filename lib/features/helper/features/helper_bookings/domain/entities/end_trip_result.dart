import 'package:equatable/equatable.dart';

class EndTripResult extends Equatable {
  final double earnings;
  final String? paymentMethod;
  final String? paymentStatus;
  final double? finalPrice;

  const EndTripResult({
    required this.earnings,
    this.paymentMethod,
    this.paymentStatus,
    this.finalPrice,
  });

  factory EndTripResult.fromResponse(dynamic raw) {
    final root = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    final data = root['data'];
    final payload = data is Map ? Map<String, dynamic>.from(data) : root;
    final booking = payload['booking'] is Map
        ? Map<String, dynamic>.from(payload['booking'] as Map)
        : null;

    var earnings = _readAmount(payload);
    if (earnings <= 0 && booking != null) {
      earnings = _readAmount(booking);
    }

    return EndTripResult(
      earnings: earnings,
      paymentMethod:
          _readString(payload, 'paymentMethod') ??
          _readString(booking, 'paymentMethod') ??
          _readString(payload, 'method') ??
          _readNestedPaymentString(payload, 'method') ??
          _readNestedPaymentString(booking, 'method') ??
          _readLatestPaymentString(payload, 'method') ??
          _readLatestPaymentString(booking, 'method'),
      paymentStatus:
          _readString(payload, 'paymentStatus') ??
          _readString(booking, 'paymentStatus') ??
          _readNestedPaymentString(payload, 'status') ??
          _readLatestPaymentString(payload, 'status'),
      finalPrice:
          _readDouble(payload, 'finalPrice') ??
          _readDouble(booking, 'finalPrice'),
    );
  }

  EndTripResult mergeBookingFallback({
    required double payout,
    String? paymentMethod,
    String? paymentStatus,
    double? finalPrice,
  }) {
    return EndTripResult(
      earnings: earnings > 0 ? earnings : (payout > 0 ? payout : earnings),
      paymentMethod: (this.paymentMethod?.isNotEmpty ?? false)
          ? this.paymentMethod
          : paymentMethod,
      paymentStatus: (this.paymentStatus?.isNotEmpty ?? false)
          ? this.paymentStatus
          : paymentStatus,
      finalPrice: this.finalPrice ?? finalPrice,
    );
  }

  EndTripResult copyWith({
    double? earnings,
    String? paymentMethod,
    String? paymentStatus,
    double? finalPrice,
  }) {
    return EndTripResult(
      earnings: earnings ?? this.earnings,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      finalPrice: finalPrice ?? this.finalPrice,
    );
  }

  static String? _readNestedPaymentString(Map<String, dynamic>? map, String key) {
    if (map == null) return null;
    final payment = map['payment'];
    if (payment is! Map) return null;
    final nested = Map<String, dynamic>.from(payment);
    return _readString(nested, key);
  }

  static String? _readLatestPaymentString(Map<String, dynamic>? map, String key) {
    if (map == null) return null;
    final latest = map['latestPayment'] ?? map['LatestPayment'];
    if (latest is! Map) return null;
    final nested = Map<String, dynamic>.from(latest);
    return _readString(nested, key);
  }

  static String? _readString(Map<String, dynamic>? map, String key) {
    if (map == null) return null;
    final value = map[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static double? _readDouble(Map<String, dynamic>? map, String key) {
    if (map == null) return null;
    return _parsePositiveDouble(map[key]);
  }

  static double? _parsePositiveDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) {
      final parsed = value.toDouble();
      return parsed > 0 ? parsed : null;
    }
    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  static double _readAmount(Map<String, dynamic> map) {
    const keys = [
      'earnings',
      'finalPayout',
      'estimatedPayout',
      'payout',
      'helperPayout',
      'netPayout',
      'netAmount',
      'amount',
    ];
    for (final key in keys) {
      final parsed = _parsePositiveDouble(map[key]);
      if (parsed != null) return parsed;
    }

    final breakdown = map['priceBreakdown'];
    if (breakdown is Map) {
      final nested = Map<String, dynamic>.from(breakdown);
      for (final key in ['helperPayout', 'estimatedPayout', 'finalPayout']) {
        final parsed = _parsePositiveDouble(nested[key]);
        if (parsed != null) return parsed;
      }
    }

    return 0;
  }

  @override
  List<Object?> get props =>
      [earnings, paymentMethod, paymentStatus, finalPrice];
}
