import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../../../core/config/api_config.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../models/language_model.dart';
import '../models/interview_model.dart';

abstract class InterviewRemoteDataSource {
  Future<List<LanguageModel>> getLanguages({CancelToken? cancelToken});
  Future<InterviewModel> startInterview(String code, {CancelToken? cancelToken});
  Future<InterviewModel> getInterview(String id, {CancelToken? cancelToken});
  Future<void> submitAnswer(String id, int questionIndex, File videoFile, {CancelToken? cancelToken});
  Future<void> submitInterview(String id, {CancelToken? cancelToken});
}

class InterviewRemoteDataSourceImpl implements InterviewRemoteDataSource {
  final Dio dio;

  InterviewRemoteDataSourceImpl(this.dio);

  @override
  Future<List<LanguageModel>> getLanguages({CancelToken? cancelToken}) async {
    try {
      final response = await dio.get(ApiConfig.getLanguages, cancelToken: cancelToken);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => LanguageModel.fromJson(json)).toList();
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to load languages');
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) throw ServerException('Request cancelled');
      throw ServerException(e.response?.data['message'] ?? e.message);
    }
  }

  @override
  Future<InterviewModel> startInterview(String code, {CancelToken? cancelToken}) async {
    try {
      final response = await dio.post(ApiConfig.startInterview(code), cancelToken: cancelToken);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return InterviewModel.fromJson(response.data['data']);
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to start interview');
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) throw ServerException('Request cancelled');
      throw ServerException(e.response?.data['message'] ?? e.message);
    }
  }

  @override
  Future<InterviewModel> getInterview(String id, {CancelToken? cancelToken}) async {
    try {
      final response = await dio.get(ApiConfig.getInterview(id), cancelToken: cancelToken);
      if (response.statusCode == 200) {
        return InterviewModel.fromJson(response.data['data']);
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to load interview');
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) throw ServerException('Request cancelled');
      throw ServerException(e.response?.data['message'] ?? e.message);
    }
  }

  @override
  Future<void> submitAnswer(String id, int questionIndex, File videoFile, {CancelToken? cancelToken}) async {
    try {
      final fileName = videoFile.path.split('/').last;
      final formData = FormData.fromMap({
        'questionIndex': questionIndex,
        'videoFile': await MultipartFile.fromFile(
          videoFile.path,
          filename: fileName,
        ),
      });

      final response = await dio.post(
        ApiConfig.submitAnswer(id),
        data: formData,
        cancelToken: cancelToken,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(response.data['message'] ?? 'Failed to submit answer');
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) throw ServerException('Request cancelled');
      throw ServerException(e.response?.data['message'] ?? e.message);
    }
  }

  @override
  Future<void> submitInterview(String id, {CancelToken? cancelToken}) async {
    try {
      final response = await dio.post(ApiConfig.submitInterview(id), cancelToken: cancelToken);
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(response.data['message'] ?? 'Failed to submit interview');
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) throw ServerException('Request cancelled');
      throw ServerException(e.response?.data['message'] ?? e.message);
    }
  }
}
