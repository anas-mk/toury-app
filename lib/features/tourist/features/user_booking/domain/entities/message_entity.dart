class MessageEntity {
  final String id;
  final String text;
  final String messageType;
  final DateTime createdAt;
  final String senderId;
  final String senderRole;
  final bool isRead;
  final bool isSending;
  final bool isFailed;

  const MessageEntity({
    required this.id,
    required this.text,
    required this.messageType,
    required this.createdAt,
    required this.senderId,
    required this.senderRole,
    this.isRead = false,
    this.isSending = false,
    this.isFailed = false,
  });

  MessageEntity copyWith({
    String? id,
    String? text,
    String? messageType,
    DateTime? createdAt,
    String? senderId,
    String? senderRole,
    bool? isRead,
    bool? isSending,
    bool? isFailed,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      text: text ?? this.text,
      messageType: messageType ?? this.messageType,
      createdAt: createdAt ?? this.createdAt,
      senderId: senderId ?? this.senderId,
      senderRole: senderRole ?? this.senderRole,
      isRead: isRead ?? this.isRead,
      isSending: isSending ?? this.isSending,
      isFailed: isFailed ?? this.isFailed,
    );
  }
}
