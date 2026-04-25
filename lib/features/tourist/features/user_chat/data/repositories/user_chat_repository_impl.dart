import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../../../../../../core/errors/failures.dart';
import '../../domain/entities/chat_entities.dart';
import '../../domain/repositories/user_chat_repository.dart';
import '../datasources/user_chat_remote_datasource.dart';

class UserChatRepositoryImpl implements UserChatRepository {
  final UserChatRemoteDataSource remoteDataSource;

  UserChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ChatConversationEntity>> getConversation(String bookingId) async {
    try {
      final conversation = await remoteDataSource.getConversation(bookingId);
      return Right(conversation);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessageEntity>>> getMessages(
    String bookingId, {
    int page = 1,
    DateTime? beforeDate,
  }) async {
    try {
      final messages = await remoteDataSource.getMessages(bookingId, page: page, beforeDate: beforeDate);
      return Right(messages);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChatMessageEntity>> sendMessage({
    required String bookingId,
    required String text,
    required String type,
  }) async {
    try {
      final message = await remoteDataSource.sendMessage(bookingId: bookingId, text: text, type: type);
      return Right(message);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String bookingId) async {
    try {
      await remoteDataSource.markAsRead(bookingId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<ChatMessageEntity> listenIncomingMessages() {
    return remoteDataSource.listenIncomingMessages();
  }
}
