import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../../core/entities/location_entity.dart';
import '../../../user_booking/presentation/pages/search_helpers_page.dart';
import 'search_location_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Toury Maps')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(30.0444, 31.2357),
              initialZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.toury',
              ),
            ],
          ),
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final LocationEntity? location = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchLocationPage()),
                      );

                      if (location != null && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SearchHelpersPage(), // Integrates seamlessly
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.location_on),
                    label: const Text('Choose Location'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchHelpersPage()),
                      );
                    },
                    icon: const Icon(Icons.person_search),
                    label: const Text('Book a Helper'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}