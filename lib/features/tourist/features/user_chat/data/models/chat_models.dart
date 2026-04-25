import '../../domain/entities/chat_entities.dart';

class ChatConversationModel extends ChatConversationEntity {
  const ChatConversationModel({
    required super.id,
    required super.bookingId,
    required super.status,
    required ChatUserModel super.user,
    required ChatUserModel super.helper,
    super.lastMessagePreview,
    super.lastMessageAt,
    required super.messageCount,
    required super.unreadCount,
  });

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    return ChatConversationModel(
      id: json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      status: json['status'] ?? '',
      user: ChatUserModel.fromJson(json['user'] ?? {}),
      helper: ChatUserModel.fromJson(json['helper'] ?? {}),
      lastMessagePreview: json['lastMessagePreview'],
      lastMessageAt: json['lastMessageAt'] != null ? DateTime.parse(json['lastMessageAt']) : null,
      messageCount: (json['messageCount'] ?? 0).toInt(),
      unreadCount: (json['unreadCount'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'status': status,
      'user': (user as ChatUserModel).toJson(),
      'helper': (helper as ChatUserModel).toJson(),
      'lastMessagePreview': lastMessagePreview,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'messageCount': messageCount,
      'unreadCount': unreadCount,
    };
  }
}

class ChatUserModel extends ChatUserEntity {
  const ChatUserModel({
    required super.id,
    required super.name,
    super.profileImageUrl,
  });

  factory ChatUserModel.fromJson(Map<String, dynamic> json) {
    return ChatUserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      profileImageUrl: json['profileImageUrl'],
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
    required super.sentAt,
    required super.isRead,
    super.readAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderType: json['senderType'] ?? '',
      messageType: json['messageType'] ?? 'Text',
      text: json['text'] ?? '',
      sentAt: DateTime.parse(json['sentAt'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderType': senderType,
      'messageType': messageType,
      'text': text,
      'sentAt': sentAt.toIso8601String(),
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
    };
  }
}
