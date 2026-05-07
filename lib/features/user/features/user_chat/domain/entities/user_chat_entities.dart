import 'package:equatable/equatable.dart';

class ChatUserEntity extends Equatable {
  final String id;
  final String name;
  final String profileImageUrl;

  const ChatUserEntity({
    required this.id,
    required this.name,
    required this.profileImageUrl,
  });

  @override
  List<Object?> get props => [id, name, profileImageUrl];
}

class ChatMessageEntity extends Equatable {
  final String id;
  final String senderId;
  final String senderType; // 'User' or 'Helper'
  final String messageType; // 'Text', 'Image', etc.
  final String text;
  final String? languageCode;
  final bool isRead;
  final DateTime? readAt;
  final DateTime sentAt;
  final bool isPending; // For optimistic UI

  const ChatMessageEntity({
    required this.id,
    required this.senderId,
    required this.senderType,
    required this.messageType,
    required this.text,
    this.languageCode,
    required this.isRead,
    this.readAt,
    required this.sentAt,
    this.isPending = false,
  });

  @override
  List<Object?> get props => [
        id,
        senderId,
        senderType,
        messageType,
        text,
        languageCode,
        isRead,
        readAt,
        sentAt,
        isPending,
      ];
}

class ChatConversationEntity extends Equatable {
  final String id;
  final String bookingId;
  final String status;
  final ChatUserEntity user;
  final ChatUserEntity helper;
  final DateTime createdAt;
  final DateTime? activatedAt;
  final DateTime? archivedAt;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final int messageCount;
  final int unreadCount;

  const ChatConversationEntity({
    required this.id,
    required this.bookingId,
    required this.status,
    required this.user,
    required this.helper,
    required this.createdAt,
    this.activatedAt,
    this.archivedAt,
    this.lastMessageAt,
    this.lastMessagePreview,
    required this.messageCount,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [
        id,
        bookingId,
        status,
        user,
        helper,
        createdAt,
        activatedAt,
        archivedAt,
        lastMessageAt,
        lastMessagePreview,
        messageCount,
        unreadCount,
      ];
}
