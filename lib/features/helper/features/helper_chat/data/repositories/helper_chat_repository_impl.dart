import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../../../../../../core/errors/failures.dart';
import '../../domain/entities/helper_chat_entities.dart';
import '../../domain/repositories/helper_chat_repository.dart';
import '../datasources/helper_chat_remote_data_source.dart';

class HelperChatRepositoryImpl implements HelperChatRepository {
  final HelperChatRemoteDataSource remoteDataSource;

  HelperChatRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, ConversationEntity>> getConversation(String bookingId) async {
    try {
      final result = await remoteDataSource.getConversation(bookingId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessageEntity>>> getMessages(
    String bookingId, {
    DateTime? before,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final result = await remoteDataSource.getMessages(
        bookingId,
        before: before,
        page: page,
        pageSize: pageSize,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChatMessageEntity>> sendMessage(String bookingId, String text) async {
    try {
      final result = await remoteDataSource.sendMessage(bookingId, text);
      return Right(result);
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

}
