import '../../domain/entities/message_entity.dart';

class MessageModel extends MessageEntity {
  const MessageModel({
    required super.id,
    required super.text,
    required super.messageType,
    required super.createdAt,
    required super.senderId,
    required super.senderRole,
    super.isRead,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id']?.toString() ?? '',
      text: json['text'] ?? '',
      messageType: json['messageType'] ?? 'Text',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']).toLocal() : DateTime.now(),
      senderId: json['senderId']?.toString() ?? '',
      senderRole: json['senderRole'] ?? 'Unknown',
      isRead: json['isRead'] ?? false,
    );
  }
}
