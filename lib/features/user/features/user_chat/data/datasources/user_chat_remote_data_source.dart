import 'package:dio/dio.dart';
import '../../../../../../core/config/api_config.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../models/user_chat_models.dart';

abstract class UserChatRemoteDataSource {
  Future<ChatConversationModel> getConversation(String bookingId, {CancelToken? cancelToken});
  Future<List<ChatMessageModel>> getMessages(
    String bookingId, {
    DateTime? beforeDateTime,
    int page = 1,
    int pageSize = 50,
    CancelToken? cancelToken,
  });
  Future<ChatMessageModel> sendMessage(String bookingId, String text, String messageType, {CancelToken? cancelToken});
  Future<void> markAsRead(String bookingId, {CancelToken? cancelToken});
}

class UserChatRemoteDataSourceImpl implements UserChatRemoteDataSource {
  final Dio dio;
  UserChatRemoteDataSourceImpl(this.dio);

  String _msg(DioException e) {
    if (CancelToken.isCancel(e)) return 'Request cancelled';
    final data = e.response?.data;
    if (data is Map) return (data['message'] ?? data['error'] ?? 'Request failed').toString();
    return e.message ?? 'Connection error. Please try again.';
  }

  void _assertOk(Response response) {
    final s = response.statusCode ?? 0;
    if (s == 400) {
      final d = response.data;
      throw ValidationException(d is Map ? (d['message'] ?? d['error'] ?? 'Validation error').toString() : 'Validation error');
    }
    if (s == 401) throw UnauthorizedException();
    if (s == 403) throw ForbiddenException();
    if (s == 404) throw NotFoundException();
    if (s >= 400) {
      final d = response.data;
      throw ServerException(d is Map ? (d['message'] ?? 'Request failed').toString() : 'Request failed');
    }
  }

  Map<String, dynamic> _data(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw['data'] is Map<String, dynamic>) return raw['data'] as Map<String, dynamic>;
      return raw;
    }
    return {};
  }

  @override
  Future<ChatConversationModel> getConversation(String bookingId, {CancelToken? cancelToken}) async {
    try {
      final res = await dio.get(ApiConfig.getChatConversation(bookingId), cancelToken: cancelToken);
      _assertOk(res);
      return ChatConversationModel.fromJson(_data(res.data));
    } on DioException catch (e) {
      throw ServerException(_msg(e));
    }
  }

  @override
  Future<List<ChatMessageModel>> getMessages(
    String bookingId, {
    DateTime? beforeDateTime,
    int page = 1,
    int pageSize = 50,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await dio.get(
        ApiConfig.getChatMessages(
          bookingId, 
          page: page, 
          pageSize: pageSize, 
          beforeDateTime: beforeDateTime?.toUtc().toIso8601String()
        ),
        cancelToken: cancelToken,
      );
      _assertOk(res);
      final raw = res.data;
      final list = (raw is Map && raw['data'] is Map && raw['data']['items'] is List)
          ? raw['data']['items'] as List
          : ((raw is Map && raw['data'] is List) ? raw['data'] as List : (raw is List ? raw : []));
      
      return list.map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e));
    }
  }

  @override
  Future<ChatMessageModel> sendMessage(String bookingId, String text, String messageType, {CancelToken? cancelToken}) async {
    try {
      final res = await dio.post(
        ApiConfig.sendChatMessage(bookingId),
        data: {'text': text, 'messageType': messageType},
        cancelToken: cancelToken,
      );
      _assertOk(res);
      return ChatMessageModel.fromJson(_data(res.data));
    } on DioException catch (e) {
      throw ServerException(_msg(e));
    }
  }

  @override
  Future<void> markAsRead(String bookingId, {CancelToken? cancelToken}) async {
    try {
      final res = await dio.post(ApiConfig.markChatAsRead(bookingId), cancelToken: cancelToken);
      _assertOk(res);
    } on DioException catch (e) {
      throw ServerException(_msg(e));
    }
  }
}
