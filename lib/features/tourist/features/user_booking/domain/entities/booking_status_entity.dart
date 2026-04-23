class BookingStatusEntity {
  final String bookingId;
  final String status;
  final DateTime updatedAt;

  const BookingStatusEntity({
    required this.bookingId,
    required this.status,
    required this.updatedAt,
  });
}
