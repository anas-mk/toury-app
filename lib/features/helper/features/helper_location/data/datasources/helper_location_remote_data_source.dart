import 'package:dio/dio.dart';
import '../../../../../../core/config/api_config.dart';
import '../models/helper_location_models.dart';

abstract class HelperLocationRemoteDataSource {
  Future<void> updateLocation(HelperLocationModel location);
  Future<LocationStatusModel> getLocationStatus();
  Future<InstantEligibilityModel> getInstantEligibility();
}

class HelperLocationRemoteDataSourceImpl implements HelperLocationRemoteDataSource {
  final Dio dio;

  HelperLocationRemoteDataSourceImpl(this.dio);

  @override
  Future<void> updateLocation(HelperLocationModel location) async {
    await dio.post(ApiConfig.helperLocationUpdate, data: location.toJson());
  }

  @override
  Future<LocationStatusModel> getLocationStatus() async {
    final response = await dio.get(ApiConfig.helperLocationStatus);
    return LocationStatusModel.fromJson(response.data['data'] ?? response.data);
  }

  @override
  Future<InstantEligibilityModel> getInstantEligibility() async {
    final response = await dio.get(ApiConfig.helperLocationEligibility);
    return InstantEligibilityModel.fromJson(response.data['data'] ?? response.data);
  }
}
