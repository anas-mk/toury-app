class BookingEntity {
  final String id;
  final String helperId;
  final String touristId;
  final String status;
  final String type; // 'scheduled' or 'instant'
  final DateTime createdAt;
  final DateTime? scheduledDate;

  const BookingEntity({
    required this.id,
    required this.helperId,
    required this.touristId,
    required this.status,
    required this.type,
    required this.createdAt,
    this.scheduledDate,
  });
}
