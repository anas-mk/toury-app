import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../../../core/errors/exceptions.dart';
import '../../domain/entities/location.dart';
import '../models/route_info_model.dart';
import 'routing_data_source.dart';

/// Data Source Implementation - Routing
class RoutingDataSourceImpl implements RoutingDataSource {
  final http.Client client;
  static const String baseUrl = 'https://router.project-osrm.org/route/v1';

  RoutingDataSourceImpl({required this.client});

  @override
  Future<RouteInfoModel> getRoute({
    required Location start,
    required Location destination,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl/driving/'
            '${start.longitude},${start.latitude};'
            '${destination.longitude},${destination.latitude}'
            '?overview=full&geometries=geojson',
      );

      final response = await client.get(url).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RouteInfoModel.fromOSRMJson(data, start, destination);
      } else {
        throw ServerException(
            'Failed to get route: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to get route: $e');
    }
  }
}