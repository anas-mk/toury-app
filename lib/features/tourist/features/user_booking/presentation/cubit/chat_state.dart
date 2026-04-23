import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/message_entity.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final ChatEntity chatInfo;
  final List<MessageEntity> messages;
  final bool hasReachedMax;
  final bool isLoadingMore;

  const ChatLoaded({
    required this.chatInfo,
    required this.messages,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
  });

  ChatLoaded copyWith({
    ChatEntity? chatInfo,
    List<MessageEntity>? messages,
    bool? hasReachedMax,
    bool? isLoadingMore,
  }) {
    return ChatLoaded(
      chatInfo: chatInfo ?? this.chatInfo,
      messages: messages ?? this.messages,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [chatInfo, messages, hasReachedMax, isLoadingMore];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}
