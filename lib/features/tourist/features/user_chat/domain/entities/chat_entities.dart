import 'package:equatable/equatable.dart';

class ChatConversationEntity extends Equatable {
  final String id;
  final String bookingId;
  final String status;
  final ChatUserEntity user;
  final ChatUserEntity helper;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final int messageCount;
  final int unreadCount;

  const ChatConversationEntity({
    required this.id,
    required this.bookingId,
    required this.status,
    required this.user,
    required this.helper,
    this.lastMessagePreview,
    this.lastMessageAt,
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
        lastMessagePreview,
        lastMessageAt,
        messageCount,
        unreadCount,
      ];
}

class ChatUserEntity extends Equatable {
  final String id;
  final String name;
  final String? profileImageUrl;

  const ChatUserEntity({
    required this.id,
    required this.name,
    this.profileImageUrl,
  });

  @override
  List<Object?> get props => [id, name, profileImageUrl];
}

class ChatMessageEntity extends Equatable {
  final String id;
  final String senderId;
  final String senderType; // 'User' | 'Helper'
  final String messageType; // 'Text' | 'Image' | 'File'
  final String text;
  final DateTime sentAt;
  final bool isRead;
  final DateTime? readAt;

  const ChatMessageEntity({
    required this.id,
    required this.senderId,
    required this.senderType,
    required this.messageType,
    required this.text,
    required this.sentAt,
    required this.isRead,
    this.readAt,
  });

  @override
  List<Object?> get props => [
        id,
        senderId,
        senderType,
        messageType,
        text,
        sentAt,
        isRead,
        readAt,
      ];
}
