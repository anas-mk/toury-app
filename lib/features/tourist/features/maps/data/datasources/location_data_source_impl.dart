import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../../../../../core/errors/exceptions.dart';
import '../models/location_model.dart';
import 'location_data_source.dart';

/// Data Source Implementation - Location
class LocationDataSourceImpl implements LocationDataSource {
  final http.Client client;

  LocationDataSourceImpl({required this.client});

  @override
  Future<LocationModel> getCurrentLocation() async {
    try {
      // التحقق من الصلاحيات
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw LocationException('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw LocationException(
            'Location permissions are permanently denied');
      }

      // الحصول على الموقع
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      if (e is LocationException) rethrow;
      throw LocationException('Failed to get current location: $e');
    }
  }

  @override
  Future<List<LocationModel>> searchLocations(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      // تأخير بسيط لتجنب rate limiting
      await Future.delayed(const Duration(milliseconds: 500));

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?'
            'q=${Uri.encodeComponent(query)}&'
            'format=json&'
            'limit=10&'
            'addressdetails=1&'
            'countrycodes=eg&'
            'accept-language=en',
      );

      final response = await client.get(
        url,
        headers: {
          'User-Agent':
          'TouryApp/1.0 (Flutter Mobile App; contact@touryapp.com)',
          'Accept': 'application/json',
          'Accept-Language': 'en',
          'Referer': 'https://touryapp.com',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => LocationModel.fromJson(json)).toList();
      } else if (response.statusCode == 429 || response.statusCode == 418) {
        throw ServerException('Rate limited. Please try again later.');
      } else {
        throw ServerException(
            'Failed to search locations: ${response.statusCode}');
      }
    } on TimeoutException {
      throw ServerException('Search timeout. Please check your connection.');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to search locations: $e');
    }
  }

  @override
  Stream<LocationModel> watchCurrentLocation() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings)
        .map((position) => LocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
    ));
  }
}