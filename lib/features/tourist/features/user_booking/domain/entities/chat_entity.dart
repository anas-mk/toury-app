class ChatEntity {
  final String bookingId;
  final String helperId;
  final String helperName;
  final String? helperImage;
  final String touristName;
  final String? touristImage;
  final bool isOnline;

  const ChatEntity({
    required this.bookingId,
    required this.helperId,
    required this.helperName,
    this.helperImage,
    this.touristName = 'Customer',
    this.touristImage,
    this.isOnline = false,
  });
}
