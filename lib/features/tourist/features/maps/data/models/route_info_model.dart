import '../../domain/entities/location.dart';
import '../../domain/entities/route_info.dart';
import 'location_model.dart';

/// Data Model - RouteInfo
class RouteInfoModel extends RouteInfo {
  const RouteInfoModel({
    required super.start,
    required super.destination,
    required super.points,
    required super.distanceInKm,
    required super.durationInMinutes,
  });

  /// من JSON (OSRM Response)
  factory RouteInfoModel.fromOSRMJson(
      Map<String, dynamic> json,
      Location start,
      Location destination,
      ) {
    final route = json['routes'][0];
    final coordinates = route['geometry']['coordinates'] as List;

    final points = coordinates
        .map((coord) => LocationModel(
      latitude: (coord[1] as num).toDouble(),
      longitude: (coord[0] as num).toDouble(),
    ))
        .toList();

    return RouteInfoModel(
      start: start,
      destination: destination,
      points: points,
      distanceInKm: (route['distance'] as num) / 1000,
      durationInMinutes: (route['duration'] as num) / 60,
    );
  }

  /// إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'start': LocationModel.fromEntity(start).toJson(),
      'destination': LocationModel.fromEntity(destination).toJson(),
      'points': points
          .map((p) => LocationModel.fromEntity(p).toJson())
          .toList(),
      'distance_km': distanceInKm,
      'duration_min': durationInMinutes,
    };
  }

  /// من Domain Entity
  factory RouteInfoModel.fromEntity(RouteInfo route) {
    return RouteInfoModel(
      start: route.start,
      destination: route.destination,
      points: route.points,
      distanceInKm: route.distanceInKm,
      durationInMinutes: route.durationInMinutes,
    );
  }
}