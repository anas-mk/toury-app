import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../../../../../../core/errors/failures.dart';
import '../../domain/entities/helper_chat_entities.dart';
import '../../domain/repositories/helper_chat_repository.dart';
import '../datasources/helper_chat_remote_data_source.dart';
import '../services/helper_chat_signalr_service.dart';

class HelperChatRepositoryImpl implements HelperChatRepository {
  final HelperChatRemoteDataSource remoteDataSource;
  final HelperChatSignalRService signalRService;

  HelperChatRepositoryImpl({
    required this.remoteDataSource,
    required this.signalRService,
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

  @override
  Future<void> connectSignalR(String token) => signalRService.connect(token);

  @override
  Future<void> disconnectSignalR() => signalRService.disconnect();

  @override
  Stream<ChatMessageEntity> get messageStream => signalRService.messageStream;
}
