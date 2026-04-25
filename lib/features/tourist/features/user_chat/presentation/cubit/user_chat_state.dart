import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_entities.dart';

abstract class UserChatState extends Equatable {
  const UserChatState();

  @override
  List<Object?> get props => [];
}

class UserChatInitial extends UserChatState {}

class UserChatLoading extends UserChatState {}

class UserChatLoaded extends UserChatState {
  final ChatConversationEntity conversation;
  final List<ChatMessageEntity> messages;
  final bool hasMore;
  final bool isPaginationLoading;

  const UserChatLoaded({
    required this.conversation,
    required this.messages,
    this.hasMore = false,
    this.isPaginationLoading = false,
  });

  UserChatLoaded copyWith({
    ChatConversationEntity? conversation,
    List<ChatMessageEntity>? messages,
    bool? hasMore,
    bool? isPaginationLoading,
  }) {
    return UserChatLoaded(
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      hasMore: hasMore ?? this.hasMore,
      isPaginationLoading: isPaginationLoading ?? this.isPaginationLoading,
    );
  }

  @override
  List<Object?> get props => [conversation, messages, hasMore, isPaginationLoading];
}

class UserChatError extends UserChatState {
  final String message;

  const UserChatError(this.message);

  @override
  List<Object?> get props => [message];
}
