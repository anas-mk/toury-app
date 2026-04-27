/// Client-side choice for POST initiate.
enum AppPaymentMethod {
  cash,
  mockCard;

  String get apiName => this == AppPaymentMethod.cash ? 'Cash' : 'MockCard';
}

