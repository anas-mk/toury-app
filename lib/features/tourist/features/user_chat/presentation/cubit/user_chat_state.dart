import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_entities.dart';

abstract class UserChatState extends Equatable {
  const UserChatState();

  @override
  List<Object?> get props => [];
}

class UserChatInitial extends UserChatState {}

class ChatLoading extends UserChatState {}

class ChatLoaded extends UserChatState {
  final List<ChatMessageEntity> messages;
  final bool isSending;

  const ChatLoaded({required this.messages, this.isSending = false});

  @override
  List<Object?> get props => [messages, isSending];

  ChatLoaded copyWith({
    List<ChatMessageEntity>? messages,
    bool? isSending,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
    );
  }
}

class ChatError extends UserChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}
