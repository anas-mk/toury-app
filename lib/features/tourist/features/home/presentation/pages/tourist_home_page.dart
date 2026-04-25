import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:toury/features/tourist/features/user_booking/domain/entities/helper_booking_entity.dart';
import 'package:toury/features/tourist/features/user_booking/domain/entities/search_params.dart';
import 'package:toury/features/tourist/features/user_booking/presentation/cubits/booking_status_cubit.dart';
import 'package:toury/features/tourist/features/user_booking/presentation/cubits/my_bookings_cubit.dart';
import 'package:toury/features/tourist/features/user_booking/presentation/cubits/search_helpers_cubit.dart';
import 'package:toury/features/tourist/features/user_ratings/presentation/cubit/user_ratings_cubit.dart';
import 'package:toury/features/tourist/features/user_ratings/presentation/widgets/rating_bottom_sheet.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/custom_card.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/widgets/app_network_image.dart';

class MockPOI {
  final String name;
  final LatLng location;
  MockPOI(this.name, this.location);
}

final List<MockPOI> _mockPOIs = [
  MockPOI('Cairo Tower', const LatLng(30.0459, 31.2243)),
  MockPOI('Egyptian Museum', const LatLng(30.0478, 31.2336)),
  MockPOI('Khan el-Khalili', const LatLng(30.0477, 31.2623)),
  MockPOI('Pyramids of Giza', const LatLng(29.9792, 31.1342)),
  MockPOI('Al-Azhar Park', const LatLng(30.0416, 31.2644)),
];

class TouristHomePage extends StatefulWidget {
  const TouristHomePage({super.key});

  @override
  State<TouristHomePage> createState() => _TouristHomePageState();
}

class _TouristHomePageState extends State<TouristHomePage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final _searchController = TextEditingController();
  LatLng _currentLocation = const LatLng(30.0444, 31.2357); // Cairo default
  LatLng? _destinationLocation;
  bool _isSearching = false;
  List<MockPOI> _filteredPOIs = [];
  bool _isLocationLoaded = false;
  HelperBookingEntity? _selectedHelper;
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLocationLoaded = true;
      });
      _mapController.move(_currentLocation, 14);
      _fetchNearbyHelpers();
    }
  }

  void _fetchNearbyHelpers() {
    context.read<SearchHelpersCubit>().searchInstant(InstantSearchParams(
      pickupLocationName: 'Current Location',
      pickupLatitude: _currentLocation.latitude,
      pickupLongitude: _currentLocation.longitude,
      durationInMinutes: 60,
      requestedLanguage: 'English',
      requiresCar: false,
      travelersCount: 1,
    ));
  }

  void _selectLocation(LatLng location) {
    setState(() {
      _destinationLocation = location;
      _isSearching = false;
      _searchController.clear();
    });
    _mapController.move(location, 14);
    _fitRouteBounds();
  }

  void _fitRouteBounds() {
    if (_destinationLocation == null) return;
    final bounds = LatLngBounds.fromPoints([_currentLocation, _destinationLocation!]);
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(100)));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Builder(
      builder: (context) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              _buildMap(),
              if (!_isSearching) _buildTopOverlay(context),
              if (_isSearching) _buildActiveSearchOverlay(isDark),
              _buildActiveBookingOverlay(),
              _buildFloatingActions(),
              _buildDraggableSheet(context),
            ],
          ),
        );
      }
    );
  }

  Widget _buildMap() {
    return BlocBuilder<SearchHelpersCubit, SearchHelpersState>(
      builder: (context, state) {
        List<Marker> markers = [
          Marker(
            point: _currentLocation,
            width: 80,
            height: 80,
            child: _buildUserLocationMarker(),
          ),
          if (_destinationLocation != null)
            Marker(
              point: _destinationLocation!,
              width: 50,
              height: 50,
              child: const Icon(Icons.location_on, color: Colors.black, size: 40),
            ),
        ];

        if (state is SearchHelpersLoaded) {
          markers.addAll(state.helpers.map((helper) => Marker(
            point: LatLng(helper.latitude ?? 0, helper.longitude ?? 0),
            width: 60,
            height: 60,
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedHelper = helper);
                _sheetController.animateTo(0.4, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
              },
              child: _buildHelperMarker(helper),
            ),
          )));
        }

        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLocation,
            initialZoom: 14,
            onTap: (tapPosition, point) {
              _selectLocation(point);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.toury.app',
              tileDisplay: const TileDisplay.fadeIn(),
            ),
            if (_destinationLocation != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [_currentLocation, _destinationLocation!],
                    color: Colors.black,
                    strokeWidth: 4.0,
                  ),
                ],
              ),
            MarkerLayer(markers: markers),
          ],
        );
      },
    );
  }

  Widget _buildUserLocationMarker() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColor.primaryColor.withOpacity(0.2 * (1 - value)),
            border: Border.all(color: AppColor.primaryColor.withOpacity(0.5 * (1 - value)), width: 2),
          ),
          child: Center(
            child: Container(
              width: 15,
              height: 15,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.primaryColor,
                boxShadow: [BoxShadow(color: Colors.white, blurRadius: 4)],
              ),
            ),
          ),
        );
      },
      onEnd: () {}, // Repeat logic would go here, but TweenAnimationBuilder doesn't repeat easily. 
      // Using a proper animation controller for production pulse.
    );
  }

  Widget _buildHelperMarker(HelperBookingEntity helper) {
    final isSelected = _selectedHelper?.id == helper.id;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.all(isSelected ? 4 : 2),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6)],
            border: Border.all(color: isSelected ? AppColor.primaryColor : (helper.availabilityStatus == 'AvailableNow' ? Colors.green : Colors.grey), width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: AppNetworkImage(
              imageUrl: helper.profileImageUrl ?? '',
              width: isSelected ? 40 : 30,
              height: isSelected ? 40 : 30,
            ),
          ),
        ),
        if (isSelected)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: AppColor.primaryColor, borderRadius: BorderRadius.circular(10)),
            child: Text(helper.name, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _buildTopOverlay(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isSearching = true;
            _filteredPOIs = _mockPOIs;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: isDark ? Colors.white : Colors.black, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _destinationLocation == null ? 'Where to?' : 'Selected Destination',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.access_time, size: 20, color: isDark ? Colors.white : Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSearchOverlay(bool isDark) {
    return Positioned.fill(
      child: Container(
        color: isDark ? Colors.black.withOpacity(0.9) : Colors.white.withOpacity(0.9),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 16, right: 16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (value) {
                  setState(() {
                    _filteredPOIs = _mockPOIs
                        .where((poi) => poi.name.toLowerCase().contains(value.toLowerCase()))
                        .toList();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search destinations...',
                  prefixIcon: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => _isSearching = false),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredPOIs.length,
                itemBuilder: (context, index) {
                  final poi = _filteredPOIs[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(poi.name),
                    onTap: () => _selectLocation(poi.location),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassChip(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: CustomCard(
        variant: CardVariant.glass,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        borderRadius: 20,
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColor.primaryColor),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBookingOverlay() {
    return BlocBuilder<BookingStatusCubit, BookingStatusState>(
      builder: (context, state) {
        if (state is BookingActiveFound) {
          return Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 20,
            right: 20,
            child: FadeInUp(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColor.primaryColor.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: InkWell(
                        onTap: () {
                          final b = state.booking;
                          context.push(
                            '/user-tracking/${b.id}?pickupLat=${b.pickupLatitude ?? 0}&pickupLng=${b.pickupLongitude ?? 0}&destLat=${b.destinationLatitude ?? 0}&destLng=${b.destinationLongitude ?? 0}',
                          );
                        },
                        child: Row(
                          children: [
                            _buildPulsingIcon(Icons.directions_car),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Trip in Progress',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    'Helper: ${state.booking.helper?.name ?? "..."}',
                                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 40,
                              width: 1,
                              color: Colors.white.withOpacity(0.2),
                              margin: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 24),
                              onPressed: () => context.push(
                                '/user-chat/${state.booking.id}?name=${state.booking.helper?.name ?? "Helper"}&image=${state.booking.helper?.profileImageUrl ?? ""}',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        } else if (state is BookingAwaitingPayment) {
          return Positioned(
            top: MediaQuery.of(context).padding.top + 130,
            left: 20,
            right: 20,
            child: FadeInUp(
              child: CustomCard(
                variant: CardVariant.glass,
                backgroundColor: Colors.orange.shade600.withOpacity(0.9),
                padding: const EdgeInsets.all(15),
                onTap: () => context.push('/payment-method/${state.booking.id}'),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                      child: const Icon(Icons.payment, color: Colors.white),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Payment Required', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('Helper: ${state.booking.helper?.name ?? "..."}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Text('Pay Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 5),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          );
        } else if (state is BookingAwaitingRating) {
          return Positioned(
            top: MediaQuery.of(context).padding.top + 130,
            left: 20,
            right: 20,
            child: FadeInUp(
              child: CustomCard(
                variant: CardVariant.glass,
                backgroundColor: Colors.green.shade600.withValues(alpha: 0.9),
                padding: const EdgeInsets.all(15),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => BlocProvider(
                      create: (_) => sl<UserRatingsCubit>(),
                      child: RatingBottomSheet(
                        bookingId: state.booking.id,
                        helperName: state.booking.helper?.name ?? 'your helper',
                      ),
                    ),
                  ).then((rated) {
                    if (rated == true) {
                      context.read<BookingStatusCubit>().startPollingForActive();
                    }
                  });
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                      child: const Icon(Icons.star, color: Colors.white),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rate your recent trip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('Trip with ${state.booking.helper?.name ?? "..."} is completed', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Text('Rate Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 5),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFloatingActions() {
    return Positioned(
      bottom: 120,
      right: 20,
      child: Column(
        children: [
          FloatingActionButton.small(
            onPressed: () {
              _mapController.move(_currentLocation, _mapController.camera.zoom + 1);
            },
            heroTag: 'zoom_in',
            backgroundColor: Colors.white,
            child: const Icon(Icons.add, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.small(
            onPressed: () {
              _mapController.move(_currentLocation, _mapController.camera.zoom - 1);
            },
            heroTag: 'zoom_out',
            backgroundColor: Colors.white,
            child: const Icon(Icons.remove, color: Colors.black87),
          ),
          const SizedBox(height: 15),
          FloatingActionButton(
            onPressed: _determinePosition,
            backgroundColor: AppColor.primaryColor,
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableSheet(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.12,
      minChildSize: 0.12,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 1)],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              if (_selectedHelper != null) _buildHelperPreview(_selectedHelper!)
              else _buildDefaultSheetContent(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHelperPreview(HelperBookingEntity helper) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: AppNetworkImage(imageUrl: helper.profileImageUrl ?? '', width: 70, height: 70),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(helper.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      Text(' ${helper.rating} (${helper.completedTrips} trips)', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Est. Price', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text('\$${(15 + helper.rating * 5).toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColor.primaryColor)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 25),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'View Profile',
                variant: ButtonVariant.outlined,
                onPressed: () => context.push('/helper-profile/${helper.id}'),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: CustomButton(
                text: 'Book Now',
                onPressed: () => context.push('/instant-search', extra: helper),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        const Text('About Helper', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Text(helper.bio ?? 'No bio available', style: TextStyle(color: Colors.grey[600], height: 1.5)),
        const SizedBox(height: 20),
        CustomButton(
          text: 'Clear Selection',
          variant: ButtonVariant.text,
          onPressed: () => setState(() => _selectedHelper = null),
        ),
      ],
    );
  }

  Widget _buildDefaultSheetContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Suggestions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            TextButton(onPressed: () {}, child: const Text('See all')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSuggestionBox(
                Icons.bolt,
                'Instant',
                () => context.push('/instant-search'),
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSuggestionBox(
                Icons.calendar_month,
                'Reserve',
                () => context.push('/scheduled-search'),
                isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Text('Around You', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        _buildUberListTile(Icons.person_search, 'Find a Local Helper', 'Available nearby right now', () => context.push('/instant-search')),
        _buildUberListTile(Icons.star_outline, 'Saved Guides', 'Quickly book your favorites', () {}),
      ],
    );
  }

  Widget _buildSuggestionBox(IconData icon, String title, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: isDark ? Colors.white : Colors.black),
            const SizedBox(height: 32),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildUberListTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF6F6F6),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 24, color: isDark ? Colors.white : Colors.black),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: isDark ? Colors.white54 : Colors.black54),
    );
  }

  Widget _buildPulsingIcon(IconData icon) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_pulseController.value * 0.2),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2 + (_pulseController.value * 0.1)),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.1 * _pulseController.value),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildRecentBookingItem(dynamic booking) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.history, color: Colors.grey),
      title: Text(booking.destinationCity, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(DateFormat('MMM dd').format(booking.requestedDate), style: const TextStyle(fontSize: 12)),
      onTap: () => context.push('/booking-details/${booking.id}'),
    );
  }
}

class FadeInUp extends StatefulWidget {
  final Widget child;
  const FadeInUp({super.key, required this.child});

  @override
  State<FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<FadeInUp> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offset;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _offset = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: SlideTransition(position: _offset, child: widget.child));
  }
}
