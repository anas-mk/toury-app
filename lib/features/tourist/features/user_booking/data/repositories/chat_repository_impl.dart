import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_service.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatService remoteDataSource;

  ChatRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, ChatEntity>> getChatInfo(String bookingId) async {
    try {
      final result = await remoteDataSource.getChatInfo(bookingId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> getMessages(String bookingId, {int page = 1, int pageSize = 20, DateTime? before}) async {
    try {
      final result = await remoteDataSource.getMessages(bookingId, page: page, pageSize: pageSize, before: before);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MessageEntity>> sendMessage(String bookingId, String text, String messageType) async {
    try {
      final result = await remoteDataSource.sendMessage(bookingId, text, messageType);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> markAsRead(String bookingId) async {
    try {
      await remoteDataSource.markAsRead(bookingId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
