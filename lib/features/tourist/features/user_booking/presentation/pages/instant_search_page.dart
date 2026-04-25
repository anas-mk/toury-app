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
                      child: const Icon(Icons.my_location, color: AppColor.primaryColor, size: 40),
                    ),
                    if (_destinationLocation != null)
                      Marker(
                        point: _destinationLocation!,
                        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                      ),
                  ],
                ),
              ],
            ),

            // 2. Back Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => context.pop(),
                ),
              ),
            ),

            // 3. Floating Bottom Controls
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildControls(),
            ),
          ],
        ),
      );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isSelectingDestination) ...[
            const Text('Confirm Pickup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            CustomButton(
              text: 'Set Pickup Location',
              onPressed: () => setState(() => _isSelectingDestination = true),
            ),
          ] else if (_destinationLocation == null) ...[
            const Text('Select Destination on Map', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            const Text('Tap anywhere on the map to set your destination', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 15),
            CustomButton(
              text: 'Cancel',
              variant: ButtonVariant.outlined,
              onPressed: () => setState(() => _isSelectingDestination = false),
            ),
          ] else ...[
            _buildHelperList(),
          ],
        ],
      ),
    );
  }

  Widget _buildHelperList() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Choose Your Helper', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
          child: BlocBuilder<SearchHelpersCubit, SearchHelpersState>(
            builder: (context, state) {
              if (state is SearchHelpersLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is SearchHelpersLoaded) {
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: state.helpers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
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
              return const Text('No helpers found');
            },
          ),
        ),
        const SizedBox(height: 15),
        CustomButton(
          text: 'Reset Locations',
          variant: ButtonVariant.text,
          onPressed: () => setState(() {
            _destinationLocation = null;
            _isSelectingDestination = false;
          }),
        ),
      ],
    );
  }
}
