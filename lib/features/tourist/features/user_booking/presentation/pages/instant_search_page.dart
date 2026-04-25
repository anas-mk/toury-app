import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../domain/entities/search_params.dart';
import '../../domain/entities/helper_booking_entity.dart';
import '../cubits/search_helpers_cubit.dart';
import '../widgets/helper_search_item.dart';

class InstantSearchPage extends StatefulWidget {
  final HelperBookingEntity? preSelectedHelper;
  const InstantSearchPage({super.key, this.preSelectedHelper});

  @override
  State<InstantSearchPage> createState() => _InstantSearchPageState();
}

class _InstantSearchPageState extends State<InstantSearchPage> {
  final MapController _mapController = MapController();
  LatLng _pickupLocation = const LatLng(30.0444, 31.2357);
  LatLng? _destinationLocation;
  bool _isSelectingDestination = false;
  
  final _languageController = TextEditingController(text: 'English');
  final _travelersController = TextEditingController(text: '1');
  int _duration = 60;
  bool _requiresCar = false;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _pickupLocation = LatLng(position.latitude, position.longitude);
    });
    _mapController.move(_pickupLocation, 15);
    _searchHelpers();
  }

  void _searchHelpers() {
    context.read<SearchHelpersCubit>().searchInstant(InstantSearchParams(
      pickupLocationName: 'Current Location',
      pickupLatitude: _pickupLocation.latitude,
      pickupLongitude: _pickupLocation.longitude,
      durationInMinutes: _duration,
      requestedLanguage: _languageController.text,
      requiresCar: _requiresCar,
      travelersCount: int.tryParse(_travelersController.text) ?? 1,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Stack(
        children: [
          // 1. Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pickupLocation,
              initialZoom: 15,
              onTap: (tapPosition, point) {
                if (_isSelectingDestination) {
                  setState(() => _destinationLocation = point);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.toury.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _pickupLocation,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(width: 24, height: 24, decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), shape: BoxShape.circle)),
                        Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.white, spreadRadius: 2)])),
                      ],
                    ),
                  ),
                  if (_destinationLocation != null)
                    Marker(
                      point: _destinationLocation!,
                      child: const Icon(Icons.location_on, color: Colors.black, size: 40),
                    ),
                ],
              ),
            ],
          ),

          // 2. Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: CircleAvatar(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
                onPressed: () => context.pop(),
              ),
            ),
          ),

          // 3. Floating Bottom Controls
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildControls(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: isDark ? Colors.grey[800] : Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
          ),
          if (!_isSelectingDestination) ...[
            const Text('Confirm Pickup Location', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Current Location', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 16)),
            const SizedBox(height: 24),
            CustomButton(text: 'Confirm Pickup', onPressed: () => setState(() => _isSelectingDestination = true), isFullWidth: true),
          ] else if (_destinationLocation == null) ...[
            const Text('Where are you going?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Tap anywhere on the map to set destination', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 16)),
            const SizedBox(height: 24),
            CustomButton(text: 'Cancel', variant: ButtonVariant.outlined, onPressed: () => setState(() => _isSelectingDestination = false), isFullWidth: true),
          ] else ...[
            _buildHelperList(isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildHelperList(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Choose a Helper', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () => setState(() {
                _destinationLocation = null;
                _isSelectingDestination = false;
              }),
              child: const Text('Reset', style: TextStyle(color: AppColor.secondaryColor, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
          child: BlocBuilder<SearchHelpersCubit, SearchHelpersState>(
            builder: (context, state) {
              if (state is SearchHelpersLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is SearchHelpersLoaded) {
                if (state.helpers.isEmpty) return const Center(child: Text('No helpers found nearby.'));
                return ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: state.helpers.length,
                  separatorBuilder: (context, index) => Divider(color: isDark ? Colors.grey[800] : Colors.grey[200]),
                  itemBuilder: (context, index) {
                    final helper = state.helpers[index];
                    return HelperSearchItem(
                      helper: helper,
                      onTap: () => context.push('/helper-profile/${helper.id}', extra: {
                        'helper': helper,
                        'isInstant': true,
                        'searchParams': InstantSearchParams(
                          pickupLocationName: 'Current Location',
                          pickupLatitude: _pickupLocation.latitude,
                          pickupLongitude: _pickupLocation.longitude,
                          durationInMinutes: _duration,
                          requestedLanguage: _languageController.text,
                          requiresCar: _requiresCar,
                          travelersCount: int.parse(_travelersController.text),
                        ),
                      }),
                    );
                  },
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }
}
