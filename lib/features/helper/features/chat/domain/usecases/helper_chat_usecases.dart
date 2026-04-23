import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../tourist/features/user_booking/domain/entities/chat_entity.dart';
import '../../../../../tourist/features/user_booking/domain/entities/message_entity.dart';
import '../../data/repositories/helper_chat_repository_impl.dart';

class GetHelperChatInfoUseCase {
  final HelperChatRepository repository;
  GetHelperChatInfoUseCase(this.repository);
  Future<Either<Failure, ChatEntity>> call(String bookingId) => repository.getChatInfo(bookingId);
}

class GetHelperMessagesUseCase {
  final HelperChatRepository repository;
  GetHelperMessagesUseCase(this.repository);
  Future<Either<Failure, List<MessageEntity>>> call(String bookingId, {int page = 1, int pageSize = 20, String? before}) =>
      repository.getMessages(bookingId, page: page, pageSize: pageSize, before: before);
}

class SendHelperMessageUseCase {
  final HelperChatRepository repository;
  SendHelperMessageUseCase(this.repository);
  Future<Either<Failure, MessageEntity>> call(String bookingId, {required String text, required String messageType}) =>
      repository.sendMessage(bookingId, text: text, messageType: messageType);
}

class MarkHelperMessagesReadUseCase {
  final HelperChatRepository repository;
  MarkHelperMessagesReadUseCase(this.repository);
  Future<Either<Failure, Unit>> call(String bookingId) => repository.markAsRead(bookingId);
}
