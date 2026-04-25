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
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_card.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/widgets/app_network_image.dart';

class TouristHomePage extends StatefulWidget {
  const TouristHomePage({super.key});

  @override
  State<TouristHomePage> createState() => _TouristHomePageState();
}

class _TouristHomePageState extends State<TouristHomePage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final _searchController = TextEditingController();
  LatLng _currentLocation = const LatLng(30.0444, 31.2357); // Cairo default
  bool _isLocationLoaded = false;
  HelperBookingEntity? _selectedHelper;
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<MyBookingsCubit>()..getBookings(pageSize: 5)),
        BlocProvider(create: (context) => sl<BookingStatusCubit>()..startPollingForActive()),
        BlocProvider(create: (context) => sl<SearchHelpersCubit>()),
      ],
      child: Builder(
        builder: (context) {
          return Scaffold(
            resizeToAvoidBottomInset: false,
            body: Stack(
              children: [
                // 1. Live Map Background
                _buildMap(),

                // 2. Top Search Bar & Greeting (Glass)
                _buildTopOverlay(context),

                // 3. Active Booking Banner (Floating)
                _buildActiveBookingOverlay(),

                // 4. Floating Action Buttons
                _buildFloatingActions(),

                // 5. Modern Bottom Sheet
                _buildDraggableSheet(context),
              ],
            ),
          );
        }
      ),
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
            onPositionChanged: (position, hasGesture) {
              // Debounced fetch could go here
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.toury.app',
              tileDisplay: const TileDisplay.fadeIn(),
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
            border: Border.all(color: isSelected ? AppColor.primaryColor : (helper.isAvailable ? Colors.green : Colors.grey), width: 2),
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
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 20,
      right: 20,
      child: Column(
        children: [
          CustomCard(
            variant: CardVariant.glass,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.menu, color: AppColor.primaryColor),
                const SizedBox(width: 15),
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push('/scheduled-search'),
                    child: Text(
                      'Where to?',
                      style: TextStyle(color: Colors.grey[600], fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const Icon(Icons.search, color: Colors.grey),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildGlassChip(Icons.home, 'Home'),
                _buildGlassChip(Icons.work, 'Work'),
                _buildGlassChip(Icons.star, 'Favorites'),
                _buildGlassChip(Icons.history, 'Recent'),
              ],
            ),
          ),
        ],
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
            top: MediaQuery.of(context).padding.top + 130,
            left: 20,
            right: 20,
            child: FadeInUp(
              child: CustomCard(
                variant: CardVariant.glass,
                backgroundColor: AppColor.primaryColor.withOpacity(0.85),
                padding: const EdgeInsets.all(15),
                onTap: () => context.push('/booking-details/${state.booking.id}'),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                      child: const Icon(Icons.directions_car, color: Colors.white),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Trip in Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('Helper: ${state.booking.helper?.name ?? "..."}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
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
                      Text(' ${helper.rating} (${helper.tripsCount} trips)', style: TextStyle(color: Colors.grey[600])),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Explore Around You', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _buildQuickAction(Icons.bolt, 'Instant Help', 'Get a helper right now', Colors.amber, () => context.push('/instant-search')),
        _buildQuickAction(Icons.calendar_month, 'Scheduled Trip', 'Plan for later', Colors.blue, () => context.push('/scheduled-search')),
        const SizedBox(height: 25),
        const Text('Recent Trips', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 15),
        BlocBuilder<MyBookingsCubit, MyBookingsState>(
          builder: (context, state) {
            if (state is MyBookingsLoaded) {
              return Column(
                children: state.bookings.take(3).map((b) => _buildRecentBookingItem(b)).toList(),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
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
