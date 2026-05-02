import '../../domain/entities/helper_chat_entities.dart';

class ChatUserModel extends ChatUserEntity {
  const ChatUserModel({
    required super.id,
    required super.name,
    required super.profileImageUrl,
  });

  factory ChatUserModel.fromJson(Map<String, dynamic> json) {
    return ChatUserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'User',
      profileImageUrl: json['profileImageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profileImageUrl': profileImageUrl,
    };
  }
}

class ChatMessageModel extends ChatMessageEntity {
  const ChatMessageModel({
    required super.id,
    required super.senderId,
    required super.senderType,
    required super.messageType,
    required super.text,
    super.languageCode,
    required super.isRead,
    super.readAt,
    required super.sentAt,
    super.isPending = false,
    super.isFailed = false,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id']?.toString() ?? json['messageId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderType: json['senderType']?.toString() ?? '',
      messageType: json['messageType']?.toString() ?? 'text',
      text: json['text']?.toString() ?? json['preview']?.toString() ?? '',
      languageCode: json['languageCode']?.toString(),
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt'].toString()) : null,
      sentAt: DateTime.parse(json['sentAt']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderType': senderType,
      'messageType': messageType,
      'text': text,
      'languageCode': languageCode,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'sentAt': sentAt.toIso8601String(),
    };
  }
}

class ConversationModel extends ConversationEntity {
  const ConversationModel({
    required super.id,
    required super.bookingId,
    required super.status,
    required super.user,
    required super.helper,
    required super.createdAt,
    super.activatedAt,
    super.archivedAt,
    super.lastMessageAt,
    super.lastMessagePreview,
    required super.messageCount,
    required super.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      status: json['status'] ?? '',
      user: ChatUserModel.fromJson(json['user'] ?? {}),
      helper: ChatUserModel.fromJson(json['helper'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      activatedAt: json['activatedAt'] != null ? DateTime.parse(json['activatedAt']) : null,
      archivedAt: json['archivedAt'] != null ? DateTime.parse(json['archivedAt']) : null,
      lastMessageAt: json['lastMessageAt'] != null ? DateTime.parse(json['lastMessageAt']) : null,
      lastMessagePreview: json['lastMessagePreview'],
      messageCount: json['messageCount'] ?? 0,
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}
