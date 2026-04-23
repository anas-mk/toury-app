import 'package:dio/dio.dart';
import 'package:toury/features/tourist/features/user_booking/data/models/chat_model.dart';

import '../../../../../tourist/features/user_booking/data/models/message_model.dart';

abstract class HelperChatService {
  Future<ChatModel> getChatInfo(String bookingId);
  Future<List<MessageModel>> getMessages(String bookingId, {int page = 1, int pageSize = 20, String? before});
  Future<MessageModel> sendMessage(String bookingId, {required String text, required String messageType});
  Future<void> markAsRead(String bookingId);
}

class HelperChatServiceImpl implements HelperChatService {
  final Dio dio;
  HelperChatServiceImpl(this.dio);

  @override
  Future<ChatModel> getChatInfo(String bookingId) async {
    final response = await dio.get('/helper/bookings/$bookingId/chat');
    return ChatModel.fromJson(response.data);
  }

  @override
  Future<List<MessageModel>> getMessages(String bookingId, {int page = 1, int pageSize = 20, String? before}) async {
    final response = await dio.get(
      '/helper/bookings/$bookingId/chat/messages',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (before != null) 'before': before,
      },
    );
    return (response.data as List).map((m) => MessageModel.fromJson(m)).toList();
  }

  @override
  Future<MessageModel> sendMessage(String bookingId, {required String text, required String messageType}) async {
    final response = await dio.post(
      '/helper/bookings/$bookingId/chat/messages',
      data: {
        'text': text,
        'messageType': messageType,
      },
    );
    return MessageModel.fromJson(response.data);
  }

  @override
  Future<void> markAsRead(String bookingId) async {
    await dio.post('/helper/bookings/$bookingId/chat/read');
  }
}
