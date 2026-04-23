import 'package:equatable/equatable.dart';

import '../../../../../tourist/features/user_booking/domain/entities/chat_entity.dart';
import '../../../../../tourist/features/user_booking/domain/entities/message_entity.dart';

abstract class HelperChatState extends Equatable {
  const HelperChatState();
  @override
  List<Object?> get props => [];
}

class HelperChatInitial extends HelperChatState {}
class HelperChatLoading extends HelperChatState {}

class HelperChatLoaded extends HelperChatState {
  final ChatEntity chatInfo;
  final List<MessageEntity> messages;
  final bool isLoadingMore;
  final bool hasReachedMax;

  const HelperChatLoaded({
    required this.chatInfo,
    required this.messages,
    this.isLoadingMore = false,
    this.hasReachedMax = false,
  });

  HelperChatLoaded copyWith({
    ChatEntity? chatInfo,
    List<MessageEntity>? messages,
    bool? isLoadingMore,
    bool? hasReachedMax,
  }) {
    return HelperChatLoaded(
      chatInfo: chatInfo ?? this.chatInfo,
      messages: messages ?? this.messages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [chatInfo, messages, isLoadingMore, hasReachedMax];
}

class HelperChatError extends HelperChatState {
  final String message;
  const HelperChatError(this.message);
  @override
  List<Object?> get props => [message];
}
