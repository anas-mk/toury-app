import 'package:dio/dio.dart';
import '../../../../../../core/config/api_config.dart';
import '../models/helper_location_models.dart';

abstract class HelperLocationRemoteDataSource {
  Future<LocationUpdateResponseModel> updateLocation(HelperLocationModel location);
  Future<LocationStatusModel> getLocationStatus();
  Future<InstantEligibilityModel> getInstantEligibility({
    double? pickupLat,
    double? pickupLng,
    String? language,
    bool? requiresCar,
  });
}

class HelperLocationRemoteDataSourceImpl implements HelperLocationRemoteDataSource {
  final Dio dio;

  HelperLocationRemoteDataSourceImpl(this.dio);

  @override
  Future<LocationUpdateResponseModel> updateLocation(HelperLocationModel location) async {
    final response = await dio.post(ApiConfig.helperLocationUpdate, data: location.toJson());
    return LocationUpdateResponseModel.fromJson(response.data['data'] ?? response.data);
  }

  @override
  Future<LocationStatusModel> getLocationStatus() async {
    final response = await dio.get(ApiConfig.helperLocationStatus);
    return LocationStatusModel.fromJson(response.data['data'] ?? response.data);
  }

  @override
  Future<InstantEligibilityModel> getInstantEligibility({
    double? pickupLat,
    double? pickupLng,
    String? language,
    bool? requiresCar,
  }) async {
    final Map<String, dynamic> queryParams = {};
    if (pickupLat != null) queryParams['pickupLatitude'] = pickupLat;
    if (pickupLng != null) queryParams['pickupLongitude'] = pickupLng;
    if (language != null) queryParams['requestedLanguage'] = language;
    if (requiresCar != null) queryParams['requiresCar'] = requiresCar;

    final response = await dio.get(
      ApiConfig.helperLocationEligibility,
      queryParameters: queryParams,
    );
    return InstantEligibilityModel.fromJson(response.data['data'] ?? response.data);
  }
}
