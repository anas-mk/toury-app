import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/entities/location_entity.dart';
import '../cubit/map_cubit.dart';
import '../cubit/map_state.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LocationEntity? _selectedLocation;
  List<Marker> _markers = [];

  final LatLng _initialPosition = const LatLng(30.0444, 31.2357); // Default to Cairo

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MapCubit>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select Location'),
        ),
        body: BlocConsumer<MapCubit, MapState>(
          listener: (context, state) {
            if (state is LocationSelected) {
              setState(() {
                _selectedLocation = state.location;
                _markers = [
                  Marker(
                    point: LatLng(state.location.lat, state.location.lng),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  )
                ];
              });
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: _initialPosition,
                    initialZoom: 12.0,
                    onTap: (tapPosition, point) {
                      context.read<MapCubit>().selectLocation(point.latitude, point.longitude);
                      // In a real app, you would also use a geocoding service here to update the address
                      context.read<MapCubit>().updateAddress('Custom Location (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})');
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.toury',
                    ),
                    MarkerLayer(
                      markers: _markers,
                    ),
                  ],
                ),
                if (_selectedLocation != null)
                  Positioned(
                    bottom: 32,
                    left: 16,
                    right: 16,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedLocation!.address,
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context, _selectedLocation);
                                },
                                child: const Text('Confirm Location'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
