import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../tourist/features/user_booking/domain/entities/chat_entity.dart';
import '../../../../../tourist/features/user_booking/domain/entities/message_entity.dart';
import '../datasources/helper_chat_service.dart';

abstract class HelperChatRepository {
  Future<Either<Failure, ChatEntity>> getChatInfo(String bookingId);
  Future<Either<Failure, List<MessageEntity>>> getMessages(String bookingId, {int page = 1, int pageSize = 20, String? before});
  Future<Either<Failure, MessageEntity>> sendMessage(String bookingId, {required String text, required String messageType});
  Future<Either<Failure, Unit>> markAsRead(String bookingId);
}

class HelperChatRepositoryImpl implements HelperChatRepository {
  final HelperChatService service;
  HelperChatRepositoryImpl(this.service);

  @override
  Future<Either<Failure, ChatEntity>> getChatInfo(String bookingId) async {
    try {
      final result = await service.getChatInfo(bookingId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> getMessages(String bookingId, {int page = 1, int pageSize = 20, String? before}) async {
    try {
      final result = await service.getMessages(bookingId, page: page, pageSize: pageSize, before: before);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MessageEntity>> sendMessage(String bookingId, {required String text, required String messageType}) async {
    try {
      final result = await service.sendMessage(bookingId, text: text, messageType: messageType);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> markAsRead(String bookingId) async {
    try {
      await service.markAsRead(bookingId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
