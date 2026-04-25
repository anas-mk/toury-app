import 'dart:async';
import 'package:dio/dio.dart';
import '../../../../../../core/config/api_config.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../models/chat_models.dart';

abstract class UserChatRemoteDataSource {
  Future<ChatConversationModel> getConversation(String bookingId);
  Future<List<ChatMessageModel>> getMessages(String bookingId, {int page = 1, DateTime? beforeDate});
  Future<ChatMessageModel> sendMessage({required String bookingId, required String text, required String type});
  Future<void> markAsRead(String bookingId);
  Stream<ChatMessageModel> listenIncomingMessages();
}

class UserChatRemoteDataSourceImpl implements UserChatRemoteDataSource {
  final Dio dio;
  // SignalR hub connection would be here in a real implementation
  // final HubConnection _hubConnection;
  
  final _messageStreamController = StreamController<ChatMessageModel>.broadcast();

  UserChatRemoteDataSourceImpl({required this.dio}) {
    // _initializeSignalR();
  }

  /*
  Future<void> _initializeSignalR() async {
    _hubConnection = HubConnectionBuilder()
        .withUrl('${ApiConfig.baseUrl}/chatHub')
        .withAutomaticReconnect()
        .build();

    _hubConnection.on('ChatMessage', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final messageJson = arguments[0] as Map<String, dynamic>;
        _messageStreamController.add(ChatMessageModel.fromJson(messageJson));
      }
    });

    await _hubConnection.start();
  }
  */

  @override
  Future<ChatConversationModel> getConversation(String bookingId) async {
    try {
      final response = await dio.get(ApiConfig.getChatConversation(bookingId));
      return ChatConversationModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] ?? e.message ?? 'Server error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<ChatMessageModel>> getMessages(String bookingId, {int page = 1, DateTime? beforeDate}) async {
    try {
      final response = await dio.get(
        ApiConfig.getChatMessages(bookingId, page: page, beforeDate: beforeDate?.toIso8601String()),
      );
      final List<dynamic> items = response.data['items'] ?? [];
      return items.map((json) => ChatMessageModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] ?? e.message ?? 'Server error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ChatMessageModel> sendMessage({required String bookingId, required String text, required String type}) async {
    try {
      final response = await dio.post(
        ApiConfig.sendChatMessage(bookingId),
        data: {
          'text': text,
          'messageType': type,
        },
      );
      return ChatMessageModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] ?? e.message ?? 'Server error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> markAsRead(String bookingId) async {
    try {
      await dio.post(ApiConfig.markChatAsRead(bookingId));
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] ?? e.message ?? 'Server error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Stream<ChatMessageModel> listenIncomingMessages() {
    return _messageStreamController.stream;
  }
}
