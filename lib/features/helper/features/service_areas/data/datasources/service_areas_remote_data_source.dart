import 'package:dio/dio.dart';
import '../../../../../../core/config/api_config.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../models/service_area_model.dart';

abstract class ServiceAreasRemoteDataSource {
  Future<List<ServiceAreaModel>> getServiceAreas({CancelToken? cancelToken});
  Future<ServiceAreaModel> createServiceArea({
    required ServiceAreaModel serviceArea,
    CancelToken? cancelToken,
  });
  Future<ServiceAreaModel> updateServiceArea({
    required String id,
    required ServiceAreaModel serviceArea,
    CancelToken? cancelToken,
  });
  Future<void> deleteServiceArea({
    required String id,
    CancelToken? cancelToken,
  });
}

class ServiceAreasRemoteDataSourceImpl implements ServiceAreasRemoteDataSource {
  final Dio dio;

  ServiceAreasRemoteDataSourceImpl(this.dio);

  String _handleDioError(DioException e) {
    if (CancelToken.isCancel(e)) return 'Request cancelled';
    final data = e.response?.data;
    if (data is Map) {
      return (data['message'] ?? data['error'] ?? 'Request failed').toString();
    }
    return e.message ?? 'Connection error. Please try again.';
  }

  void _assertSuccess(Response response) {
    final status = response.statusCode ?? 0;
    if (status == 400) {
      final data = response.data;
      final msg = data is Map
          ? (data['message'] ?? data['error'] ?? 'Validation error').toString()
          : 'Validation error';
      throw ValidationException(msg);
    }
    if (status == 401) throw UnauthorizedException();
    if (status == 403) throw ForbiddenException();
    if (status >= 400) {
      final data = response.data;
      final msg = data is Map
          ? (data['message'] ?? 'Request failed').toString()
          : 'Request failed';
      throw ServerException(msg);
    }
  }

  @override
  Future<List<ServiceAreaModel>> getServiceAreas({CancelToken? cancelToken}) async {
    try {
      final response = await dio.get(
        ApiConfig.helperServiceAreas,
        cancelToken: cancelToken,
      );
      _assertSuccess(response);
      
      final List<dynamic> data;
      if (response.data is Map && response.data['data'] is List) {
        data = response.data['data'] as List<dynamic>;
      } else if (response.data is List) {
        data = response.data as List<dynamic>;
      } else {
        data = [];
      }

      return data
          .map((json) => ServiceAreaModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    }
  }

  @override
  Future<ServiceAreaModel> createServiceArea({
    required ServiceAreaModel serviceArea,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.post(
        ApiConfig.helperServiceAreas,
        data: serviceArea.toJson(),
        cancelToken: cancelToken,
      );
      _assertSuccess(response);
      return ServiceAreaModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    }
  }

  @override
  Future<ServiceAreaModel> updateServiceArea({
    required String id,
    required ServiceAreaModel serviceArea,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.put(
        ApiConfig.helperServiceAreaById(id),
        data: serviceArea.toJson(),
        cancelToken: cancelToken,
      );
      _assertSuccess(response);
      return ServiceAreaModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    }
  }

  @override
  Future<void> deleteServiceArea({
    required String id,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.delete(
        ApiConfig.helperServiceAreaById(id),
        cancelToken: cancelToken,
      );
      _assertSuccess(response);
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    }
  }
}
