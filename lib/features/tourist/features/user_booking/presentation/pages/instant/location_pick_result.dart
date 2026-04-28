import 'package:equatable/equatable.dart';

/// Result returned from [LocationPickerPage] back to the form.
///
/// `name` is the human-readable label (e.g. "Tahrir Square, Cairo").
/// `address` is the full multi-line geocoded address (optional).
class LocationPickResult extends Equatable {
  final String name;
  final String? address;
  final double latitude;
  final double longitude;

  const LocationPickResult({
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [name, address, latitude, longitude];
}
