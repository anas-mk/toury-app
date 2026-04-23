import '../../domain/entities/chat_entity.dart';

class ChatModel extends ChatEntity {
  const ChatModel({
    required super.bookingId,
    required super.helperId,
    required super.helperName,
    super.helperImage,
    required super.touristName,
    super.touristImage,
    super.isOnline,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      bookingId: json['bookingId']?.toString() ?? '',
      helperId: json['helperId']?.toString() ?? '',
      helperName: json['helperName'] ?? 'Unknown Helper',
      helperImage: json['helperImage'],
      touristName: json['touristName'] ?? 'Customer',
      touristImage: json['touristImage'],
      isOnline: json['isOnline'] ?? false,
    );
  }
}
