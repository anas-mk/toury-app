import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../../domain/entities/user_chat_entities.dart';
import '../../domain/repositories/user_chat_repository.dart';
import '../datasources/user_chat_remote_data_source.dart';

class UserChatRepositoryImpl implements UserChatRepository {
  final UserChatRemoteDataSource remoteDataSource;

  UserChatRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, ChatConversationEntity>> getConversation(String bookingId) async {
    try {
      final result = await remoteDataSource.getConversation(bookingId);
      return Right(result as ChatConversationEntity);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessageEntity>>> getMessages(
    String bookingId, {
    DateTime? beforeDateTime,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final result = await remoteDataSource.getMessages(
        bookingId,
        beforeDateTime: beforeDateTime,
        page: page,
        pageSize: pageSize,
      );
      return Right(result.map((m) => m as ChatMessageEntity).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChatMessageEntity>> sendMessage(String bookingId, String text, String messageType) async {
    try {
      final result = await remoteDataSource.sendMessage(bookingId, text, messageType);
      return Right(result as ChatMessageEntity);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
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
}
