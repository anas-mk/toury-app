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
  final String senderType; // 'user' or 'helper'
  final String messageType; // 'text', 'image', etc.
  final String text;
  final String? languageCode;
  final bool isRead;
  final DateTime? readAt;
  final DateTime sentAt;
  final bool isPending; // For local optimistic UI
  final bool isFailed; // For error handling in optimistic UI

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
    this.isFailed = false,
  });

  ChatMessageEntity copyWith({
    String? id,
    String? senderId,
    String? senderType,
    String? messageType,
    String? text,
    String? languageCode,
    bool? isRead,
    DateTime? readAt,
    DateTime? sentAt,
    bool? isPending,
    bool? isFailed,
  }) {
    return ChatMessageEntity(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderType: senderType ?? this.senderType,
      messageType: messageType ?? this.messageType,
      text: text ?? this.text,
      languageCode: languageCode ?? this.languageCode,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      sentAt: sentAt ?? this.sentAt,
      isPending: isPending ?? this.isPending,
      isFailed: isFailed ?? this.isFailed,
    );
  }

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
        isFailed,
      ];
}

class ConversationEntity extends Equatable {
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

  const ConversationEntity({
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
