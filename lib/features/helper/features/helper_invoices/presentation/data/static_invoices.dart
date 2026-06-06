import '../../domain/entities/invoice_entities.dart';

/// Placeholder invoices shown when the API returns an empty list.
class StaticInvoices {
  StaticInvoices._();

  static List<InvoiceEntity> forFilter(String? statusFilter) {
    final filtered = statusFilter == null
        ? samples
        : samples
            .where(
              (invoice) =>
                  invoice.paymentStatus.toLowerCase() == statusFilter,
            )
            .toList();
    return List<InvoiceEntity>.from(filtered);
  }

  static final List<InvoiceEntity> samples = [
    InvoiceEntity(
      invoiceId: 'static-1',
      invoiceNumber: 'INV-2026-0042',
      bookingId: 'static-booking-1',
      userName: 'Sarah Ahmed',
      helperName: '',
      destinationCity: 'Cairo',
      totalAmount: 450,
      currency: 'EGP',
      status: 'issued',
      paymentStatus: 'paid',
      paymentMethod: 'wallet',
      issuedAt: DateTime(2026, 5, 28),
    ),
    InvoiceEntity(
      invoiceId: 'static-2',
      invoiceNumber: 'INV-2026-0038',
      bookingId: 'static-booking-2',
      userName: 'Omar Hassan',
      helperName: '',
      destinationCity: 'Giza',
      totalAmount: 320,
      currency: 'EGP',
      status: 'issued',
      paymentStatus: 'paid',
      paymentMethod: 'card',
      issuedAt: DateTime(2026, 5, 22),
    ),
    InvoiceEntity(
      invoiceId: 'static-3',
      invoiceNumber: 'INV-2026-0035',
      bookingId: 'static-booking-3',
      userName: 'Layla Mahmoud',
      helperName: '',
      destinationCity: 'Alexandria',
      totalAmount: 580,
      currency: 'EGP',
      status: 'issued',
      paymentStatus: 'pending',
      paymentMethod: 'wallet',
      issuedAt: DateTime(2026, 5, 18),
    ),
    InvoiceEntity(
      invoiceId: 'static-4',
      invoiceNumber: 'INV-2026-0029',
      bookingId: 'static-booking-4',
      userName: 'Youssef Ali',
      helperName: '',
      destinationCity: 'Luxor',
      totalAmount: 275,
      currency: 'EGP',
      status: 'cancelled',
      paymentStatus: 'cancelled',
      paymentMethod: 'wallet',
      issuedAt: DateTime(2026, 5, 10),
    ),
  ];
}
