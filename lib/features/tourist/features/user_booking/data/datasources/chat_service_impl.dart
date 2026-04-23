import 'package:dio/dio.dart';
import '../../../../../../core/config/api_config.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import 'chat_service.dart';

class ChatServiceImpl implements ChatService {
  final Dio dio;

  ChatServiceImpl(this.dio);

  @override
  Future<ChatModel> getChatInfo(String bookingId) async {
    final response = await dio.get('${ApiConfig.baseUrl}/api/user/bookings/$bookingId/chat');
    final data = response.data;
    if (data['success'] == true) {
      return ChatModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Failed to get chat info');
    }
  }

  @override
  Future<List<MessageModel>> getMessages(String bookingId, {int page = 1, int pageSize = 20, DateTime? before}) async {
    final queryParams = {
      'page': page,
      'pageSize': pageSize,
    };
    if (before != null) {
      queryParams['before'] = before.toUtc().toIso8601String() as int;
    }
    
    final response = await dio.get('${ApiConfig.baseUrl}/api/user/bookings/$bookingId/chat/messages', queryParameters: queryParams);
    final data = response.data;
    if (data['success'] == true) {
      final List items = data['data']['items'] ?? [];
      return items.map((e) => MessageModel.fromJson(e)).toList();
    } else {
      throw Exception(data['message'] ?? 'Failed to load messages');
    }
  }

  @override
  Future<MessageModel> sendMessage(String bookingId, String text, String messageType) async {
    final response = await dio.post(
      '${ApiConfig.baseUrl}/api/user/bookings/$bookingId/chat/messages',
      data: {
        'text': text,
        'messageType': messageType,
      },
    );
    final data = response.data;
    if (data['success'] == true) {
      return MessageModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Failed to send message');
    }
  }

  @override
  Future<void> markAsRead(String bookingId) async {
    final response = await dio.post('${ApiConfig.baseUrl}/api/user/bookings/$bookingId/chat/read');
    final data = response.data;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to mark as read');
    }
  }
}
