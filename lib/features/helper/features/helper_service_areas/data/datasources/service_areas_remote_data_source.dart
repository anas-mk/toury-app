import 'package:dio/dio.dart';
import '../../../../../../core/config/api_config.dart';
import '../models/service_area_models.dart';

abstract class ServiceAreasRemoteDataSource {
  Future<List<ServiceAreaModel>> getServiceAreas();
  Future<ServiceAreaModel> createServiceArea(ServiceAreaModel area);
  Future<ServiceAreaModel> updateServiceArea(String id, ServiceAreaModel area);
  Future<void> deleteServiceArea(String id);
}

class ServiceAreasRemoteDataSourceImpl implements ServiceAreasRemoteDataSource {
  final Dio dio;

  ServiceAreasRemoteDataSourceImpl(this.dio);

  @override
  Future<List<ServiceAreaModel>> getServiceAreas() async {
    final response = await dio.get(ApiConfig.helperServiceAreas);
    final List data = response.data['data'] ?? response.data;
    return data.map((json) => ServiceAreaModel.fromJson(json)).toList();
  }

  @override
  Future<ServiceAreaModel> createServiceArea(ServiceAreaModel area) async {
    final response = await dio.post(ApiConfig.helperServiceAreas, data: area.toJson());
    return ServiceAreaModel.fromJson(response.data['data'] ?? response.data);
  }

  @override
  Future<ServiceAreaModel> updateServiceArea(String id, ServiceAreaModel area) async {
    final response = await dio.put(ApiConfig.helperServiceAreaById(id), data: area.toJson());
    return ServiceAreaModel.fromJson(response.data['data'] ?? response.data);
  }

  @override
  Future<void> deleteServiceArea(String id) async {
    await dio.delete(ApiConfig.helperServiceAreaById(id));
  }
}
