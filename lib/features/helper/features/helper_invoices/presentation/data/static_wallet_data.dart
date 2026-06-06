import '../../../helper_bookings/domain/entities/helper_earnings_entities.dart';
import '../../domain/entities/invoice_entities.dart';

/// Placeholder wallet figures shown when API values are zero or empty.
class StaticWalletData {
  StaticWalletData._();

  static HelperEarnings earningsForDisplay(HelperEarnings actual) {
    return HelperEarnings(
      today: _amount(actual.today, 285),
      week: _amount(actual.week, 1240),
      month: _amount(actual.month, 4680),
      completedTrips: _count(actual.completedTrips, 12),
      recentEarnings: actual.recentEarnings.isNotEmpty
          ? actual.recentEarnings
          : sampleRecentPayouts,
      chartData: actual.chartData,
    );
  }

  static InvoiceSummaryEntity invoiceSummaryForDisplay(
    InvoiceSummaryEntity actual,
  ) {
    return InvoiceSummaryEntity(
      grossAmount: _amount(actual.grossAmount, 1625),
      commissionAmount: _amount(actual.commissionAmount, 244),
      netAmount: _amount(actual.netAmount, 1381),
      invoiceCount: _count(actual.invoiceCount, 4),
      currency: actual.currency.isNotEmpty ? actual.currency : 'EGP',
    );
  }

  static double _amount(double value, double sample) =>
      value > 0 ? value : sample;

  static int _count(int value, int sample) => value > 0 ? value : sample;

  static final List<EarningItem> sampleRecentPayouts = [
    EarningItem(
      bookingId: 'static-booking-1',
      amount: 450,
      date: DateTime(2026, 5, 28),
      travelerName: 'Sarah Ahmed',
    ),
    EarningItem(
      bookingId: 'static-booking-2',
      amount: 320,
      date: DateTime(2026, 5, 22),
      travelerName: 'Omar Hassan',
    ),
    EarningItem(
      bookingId: 'static-booking-3',
      amount: 580,
      date: DateTime(2026, 5, 18),
      travelerName: 'Layla Mahmoud',
    ),
  ];
}
