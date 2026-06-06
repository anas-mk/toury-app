import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/di/injection_container.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/widgets/app_network_image.dart';
import '../../../domain/entities/helper_booking_entity.dart';
import '../../../domain/entities/helper_booking_profile.dart';
import '../../../domain/entities/meeting_point_type.dart';
import '../../../domain/entities/search_params.dart';
import '../../cubits/booking_cubit.dart';
import '../../cubits/booking_state.dart';
import '../../cubits/helper_booking_profile_cubit.dart';
import '../instant/location_pick_result.dart';
import '../instant/location_picker_page.dart';
import 'scheduled_search_context.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kNavy = Color(0xFF000668);
const _kBlue = Color(0xFF4851C4);
const _kSurface = Color(0xFFFBF8FF);
const _kCard = Color(0xFFFFFFFF);
const _kMuted = Color(0xFF767683);
const _kContainerLow = Color(0xFFF4F2FF);
const _kContainerHigh = Color(0xFFE8E7F6);
const _kOutlineVariant = Color(0xFFC6C5D3);
const _kOnSurface = Color(0xFF1A1B25);
const _kOnSurfaceVariant = Color(0xFF464651);

const _kGradient = LinearGradient(
  colors: [_kNavy, _kBlue],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

// ── Entry point ───────────────────────────────────────────────────────────────

class ScheduledHelperProfileScreen extends StatelessWidget {
  final String helperId;
  final HelperBookingEntity? initialHelper;
  final ScheduledSearchParams? searchParams;

  const ScheduledHelperProfileScreen({
    super.key,
    required this.helperId,
    this.initialHelper,
    this.searchParams,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HelperBookingProfileCubit>(
          create: (_) => sl<HelperBookingProfileCubit>()..load(helperId),
        ),
        BlocProvider<BookingCubit>(
          create: (_) => sl<BookingCubit>(),
        ),
      ],
      child: BlocListener<BookingCubit, BookingState>(
        listener: (context, state) {
          if (state is BookingCreated) {
            context.go(
              AppRouter.bookingDetails.replaceFirst(':id', state.booking.id),
            );
          } else if (state is BookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.message,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFFE53935),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            );
          }
        },
        child: _ProfilePageBody(
          helperId: helperId,
          searchParams: searchParams,
          initialHelper: initialHelper,
        ),
      ),
    );
  }
}

// ── Stateful page body ────────────────────────────────────────────────────────

class _ProfilePageBody extends StatefulWidget {
  final String helperId;
  final ScheduledSearchParams? searchParams;
  final HelperBookingEntity? initialHelper;

  const _ProfilePageBody({
    required this.helperId,
    required this.searchParams,
    this.initialHelper,
  });

  @override
  State<_ProfilePageBody> createState() => _ProfilePageBodyState();
}

class _ProfilePageBodyState extends State<_ProfilePageBody> {
  MeetingPointType _meetingPoint = MeetingPointType.hotel;
  LocationPickResult? _meetingLocation;
  final _notesCtrl = TextEditingController();

  bool get _step2Done => _meetingLocation != null;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _priceFromSearch {
    final p = _resolvedHelper?.estimatedPrice;
    return p != null && p > 0;
  }

  HelperBookingEntity? get _resolvedHelper =>
      widget.initialHelper ??
      ScheduledSearchContext.instance.helperFor(widget.helperId);

  ScheduledSearchParams? get _resolvedParams =>
      widget.searchParams ?? ScheduledSearchContext.instance.params;

  double _estimatedTotal(HelperBookingProfile profile) {
    final fromSearch = _resolvedHelper?.estimatedPrice;
    if (fromSearch != null && fromSearch > 0) return fromSearch;

    final params = _resolvedParams;
    if (params == null) return 0;

    final helperRate = _resolvedHelper?.hourlyRate;
    if (helperRate != null && helperRate > 0) {
      return helperRate * (params.durationInMinutes / 60);
    }

    if (profile.hourlyRate > 0) {
      return profile.hourlyRate * (params.durationInMinutes / 60);
    }

    return 0;
  }

  double _serviceFee(double estTotal) =>
      _priceFromSearch ? 0 : estTotal * 0.1;

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  static LocationPickResult _airportForCity(String? city) {
    final lower = (city ?? '').toLowerCase();
    if (lower.contains('luxor')) {
      return const LocationPickResult(name: 'Luxor Intl Airport (LXR)', latitude: 25.6710, longitude: 32.7066);
    }
    if (lower.contains('aswan')) {
      return const LocationPickResult(name: 'Aswan Intl Airport (ASW)', latitude: 23.9644, longitude: 32.8200);
    }
    if (lower.contains('alex')) {
      return const LocationPickResult(name: 'Borg El Arab Airport (HBE)', latitude: 30.9177, longitude: 29.6964);
    }
    if (lower.contains('sharm')) {
      return const LocationPickResult(name: 'Sharm El Sheikh Airport (SSH)', latitude: 27.9773, longitude: 34.3950);
    }
    if (lower.contains('hurghada')) {
      return const LocationPickResult(name: 'Hurghada Intl Airport (HRG)', latitude: 27.1783, longitude: 33.7994);
    }
    if (lower.contains('marsa')) {
      return const LocationPickResult(name: 'Marsa Alam Intl Airport (RMF)', latitude: 25.5571, longitude: 34.5836);
    }
    return const LocationPickResult(name: 'Cairo Intl Airport (CAI)', latitude: 30.1219, longitude: 31.4056);
  }

  Future<void> _pickMeetingLocation(MeetingPointType type) async {
    if (type == MeetingPointType.airport) {
      final airport = _airportForCity(_resolvedParams?.destinationCity);
      setState(() {
        _meetingPoint = type;
        _meetingLocation = airport;
      });
      return;
    }

    if (type == MeetingPointType.destination) {
      final params = _resolvedParams;
      if (params != null) {
        setState(() {
          _meetingPoint = type;
          _meetingLocation = LocationPickResult(
            name: params.destinationName,
            latitude: params.destinationLatitude,
            longitude: params.destinationLongitude,
          );
        });
      }
      return;
    }

    final result = await Navigator.push<LocationPickResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(
          title: type == MeetingPointType.hotel
              ? 'Pick Hotel Location'
              : 'Pick Meeting Point',
          isPickup: true,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _meetingPoint = type;
      if (result != null) _meetingLocation = result;
    });
  }

  void _submit(BuildContext ctx, HelperBookingProfile profile) {
    if (_resolvedParams == null || _meetingLocation == null) return;
    HapticFeedback.mediumImpact();
    ctx.read<BookingCubit>().createScheduled(
          helperId: profile.helperId,
          params: _resolvedParams!,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          meetingPointType: _meetingPoint == MeetingPointType.destination
              ? MeetingPointType.custom.wire
              : _meetingPoint.wire,
          pickupLocationName: _meetingLocation!.name,
          pickupLatitude: _meetingLocation!.latitude,
          pickupLongitude: _meetingLocation!.longitude,
        );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _kSurface,
      body: BlocBuilder<HelperBookingProfileCubit, HelperBookingProfileState>(
        builder: (context, profileState) {
          if (profileState is HelperBookingProfileLoading ||
              profileState is HelperBookingProfileInitial) {
            return _ProfileSkeleton(topPad: topPad);
          }
          if (profileState is HelperBookingProfileError) {
            return _ErrorView(
              topPad: topPad,
              message: profileState.message,
              onRetry: () => context
                  .read<HelperBookingProfileCubit>()
                  .load(widget.helperId),
            );
          }
          if (profileState is! HelperBookingProfileLoaded) {
            return const SizedBox.shrink();
          }

          final profile = profileState.profile;
          final estTotal = _estimatedTotal(profile);
          final serviceFee = _serviceFee(estTotal);
          final grandTotal = estTotal + serviceFee;

          return Stack(
            children: [
              // ── Scrollable content ─────────────────────────────────────
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  top: topPad + 76,
                  bottom: 120 + bottomPad,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Sheet A: Guide Profile ─────────────────────────
                    _ProfileSection(profile: profile),

                    // ── Divider ────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      child: Container(
                        height: 1,
                        color: _kOutlineVariant.withValues(alpha: 0.35),
                      ),
                    ),

                    // ── Sheet B: Booking flow ──────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Complete Request',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: _kOnSurface,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Step indicator
                          _StepIndicator(step2Done: _step2Done),

                          const SizedBox(height: 24),

                          // Step 1 — Trip Details
                          _Step1Card(
                            params: _resolvedParams,
                            fmtDate: _fmtDate,
                          ),

                          const SizedBox(height: 20),

                          // Step 2 — Meeting Point
                          _Step2Card(
                            selected: _meetingPoint,
                            selectedLocation: _meetingLocation,
                            onTap: _pickMeetingLocation,
                          ),

                          const SizedBox(height: 20),

                          // Step 3 — Price Summary (greyed until step2 done)
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: _step2Done ? 1.0 : 0.5,
                            child: IgnorePointer(
                              ignoring: !_step2Done,
                              child: _Step3Card(
                                profile: profile,
                                params: _resolvedParams,
                                estTotal: estTotal,
                                serviceFee: serviceFee,
                                priceFromSearch: _priceFromSearch,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Fixed header ───────────────────────────────────────────
              _Header(topPad: topPad),

              // ── Sticky bottom ──────────────────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BlocBuilder<BookingCubit, BookingState>(
                  builder: (context, bookingState) {
                    final loading = bookingState is BookingLoading;
                    return _StickyBottom(
                      estTotal: grandTotal,
                      helperFirstName: profile.fullName.split(' ').first,
                      loading: loading,
                      canRequest: _resolvedParams != null &&
                          profile.canAcceptScheduled &&
                          _step2Done,
                      bottomPad: bottomPad,
                      onRequest: loading
                          ? null
                          : () => _submit(context, profile),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Fixed header (matches Stitch HTML exactly) ────────────────────────────────

class _Header extends StatelessWidget {
  final double topPad;
  const _Header({required this.topPad});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(24, topPad + 12, 24, 16),
        decoration: BoxDecoration(
          color: _kSurface.withValues(alpha: 0.88),
          boxShadow: const [
            BoxShadow(
              color: Color(0x141B237E),
              blurRadius: 32,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            // Back button — white circle
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                context.pop();
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: _kCard,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0E1B237E),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: _kOnSurface,
                  size: 20,
                ),
              ),
            ),
            // RAFIQ centered title
            Expanded(
              child: Text(
                'RAFIQ',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _kOnSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            // Account icon
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: const Icon(
                Icons.account_circle_outlined,
                color: _kOnSurfaceVariant,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sheet A: Profile section ──────────────────────────────────────────────────

class _ProfileSection extends StatelessWidget {
  final HelperBookingProfile profile;
  const _ProfileSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero gradient banner
        Container(
          height: 192,
          decoration: const BoxDecoration(
            gradient: _kGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x141B237E),
                blurRadius: 32,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.0,
                      colors: [
                        Colors.white.withValues(alpha: 0.10),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Avatar + name (overlapping the banner by -48px)
        Transform.translate(
          offset: const Offset(0, -48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Avatar (96px, border 4px white, shadow)
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _kSurface, width: 4),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x261B237E),
                          blurRadius: 32,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: profile.profileImageUrl != null
                          ? AppNetworkImage(
                              imageUrl: profile.profileImageUrl,
                              width: 96,
                              height: 96,
                              borderRadius: 48,
                            )
                          : Container(
                              color: _kContainerHigh,
                              alignment: Alignment.center,
                              child: Text(
                                profile.fullName.isNotEmpty
                                    ? profile.fullName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: _kNavy,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Name
                Center(
                  child: Text(
                    profile.fullName,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _kOnSurface,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Tagline
                Center(
                  child: Text(
                    'Senior Historical Concierge',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      color: _kOnSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Stats bento
                Container(
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x141B237E),
                        blurRadius: 32,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 20,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  profile.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: _kOnSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'RATING',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                                color: _kMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: _kOutlineVariant.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${profile.completedTrips}',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: _kOnSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'TRIPS',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                                color: _kMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: _kOutlineVariant.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${profile.experienceYears} Yrs',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: _kOnSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'EXP.',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                                color: _kMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Content section (bio, chips, areas, certs) — negative top margin
        Transform.translate(
          offset: const Offset(0, -24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // About
                if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                  Text(
                    'About ${profile.fullName.split(' ').first}',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _kOnSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile.bio!,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      color: _kOnSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Verification chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // ID Verified
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _kContainerLow,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: _kNavy.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: _kNavy,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'ID VERIFIED',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                              color: _kNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Languages
                    if (profile.languages.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _kContainerLow,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: _kOutlineVariant,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.translate_rounded,
                              size: 16,
                              color: _kOnSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              profile.languages
                                  .take(3)
                                  .map((l) => l.languageCode.toUpperCase())
                                  .join(', '),
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: _kOnSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // Service Areas
                if (profile.serviceAreas.isNotEmpty) ...[
                  const Text(
                    'SERVICE AREAS',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: _kMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.serviceAreas.map((area) {
                      final label =
                          area.areaName ?? '${area.city}, ${area.country}';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _kCard,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: _kOutlineVariant.withValues(alpha: 0.5),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x081B237E),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: _kBlue,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              label,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14,
                                color: _kOnSurface,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Certificates (bento card per cert)
                ...profile.certificates.map(
                  (cert) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _kCard,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: _kContainerHigh,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x121B237E),
                            blurRadius: 32,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _kBlue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              color: _kBlue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cert,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _kOnSurface,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'Verified certification · Active',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13,
                                    color: _kMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Step indicator ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final bool step2Done;
  const _StepIndicator({required this.step2Done});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background line
            Container(
              height: 2,
              color: _kContainerHigh,
            ),
            // Progress line (steps 1→2 always done)
            Positioned(
              left: 0,
              right: 150,
              child: Container(
                height: 2,
                decoration: const BoxDecoration(
                  gradient: _kGradient,
                ),
              ),
            ),
            // Step circles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StepDot(number: 1, done: true, active: true),
                _StepDot(number: 2, done: true, active: true),
                _StepDot(number: 3, done: false, active: false),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int number;
  final bool done;
  final bool active;
  const _StepDot({
    required this.number,
    required this.done,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: active ? _kGradient : null,
        color: active ? null : _kSurface,
        shape: BoxShape.circle,
        border: active
            ? null
            : Border.all(color: _kOutlineVariant),
        boxShadow: active
            ? [
                BoxShadow(
                  color: _kNavy.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          '$number',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : _kOnSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ── Step 1: Trip Details card ─────────────────────────────────────────────────

class _Step1Card extends StatelessWidget {
  final ScheduledSearchParams? params;
  final String Function(DateTime) fmtDate;

  const _Step1Card({required this.params, required this.fmtDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x121B237E),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STEP 1: TRIP DETAILS',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: _kMuted,
            ),
          ),
          const SizedBox(height: 16),
          if (params != null)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _DetailTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: fmtDate(params!.requestedDate),
                ),
                _DetailTile(
                  icon: Icons.people_alt_outlined,
                  label: 'Guests',
                  value: '${params!.travelersCount} Adults',
                ),
                _DetailTile(
                  icon: Icons.access_time_rounded,
                  label: 'Start Time',
                  value: params!.startTime,
                ),
                _DetailTile(
                  icon: Icons.hourglass_bottom_rounded,
                  label: 'Duration',
                  value: _durationLabel(params!.durationInMinutes),
                ),
              ],
            )
          else
            const Text(
              'No trip details provided.',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: _kMuted,
              ),
            ),
        ],
      ),
    );
  }

  static String _durationLabel(int mins) {
    if (mins == 480) return 'Full Day';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _kOutlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 18, color: _kOnSurfaceVariant),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  color: _kMuted,
                ),
              ),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kOnSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Meeting Point card ────────────────────────────────────────────────

class _Step2Card extends StatelessWidget {
  final MeetingPointType selected;
  final LocationPickResult? selectedLocation;
  final Future<void> Function(MeetingPointType) onTap;

  const _Step2Card({
    required this.selected,
    required this.selectedLocation,
    required this.onTap,
  });

  static const _options = [
    (
      MeetingPointType.hotel,
      Icons.hotel_rounded,
      'Hotel Pickup',
      'Tap to search your hotel',
    ),
    (
      MeetingPointType.airport,
      Icons.flight_land_rounded,
      'Airport Arrivals',
      'Auto-detects nearest airport',
    ),
    (
      MeetingPointType.destination,
      Icons.place_rounded,
      'Meet at Destination',
      'Guide meets you at the site',
    ),
    (
      MeetingPointType.custom,
      Icons.pin_drop_rounded,
      'Custom Location',
      'Drop a pin on the map',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _kBlue.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x121B237E),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STEP 2: MEETING POINT',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: _kMuted,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: _options.map((opt) {
              final isSelected = selected == opt.$1;
              final showLocation = isSelected && selectedLocation != null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTap(opt.$1);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _kBlue.withValues(alpha: 0.04)
                          : _kCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? _kBlue
                            : _kOutlineVariant.withValues(alpha: 0.5),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _kBlue.withValues(alpha: 0.12)
                                : _kContainerHigh.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            opt.$2,
                            size: 20,
                            color: isSelected ? _kBlue : _kOnSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                opt.$3,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _kOnSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                showLocation
                                    ? selectedLocation!.name
                                    : opt.$4,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13,
                                  color: showLocation ? _kBlue : _kMuted,
                                  fontWeight: showLocation
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Radio
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? _kBlue : _kOutlineVariant,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: _kBlue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Step 3: Price summary card ────────────────────────────────────────────────

class _Step3Card extends StatelessWidget {
  final HelperBookingProfile profile;
  final ScheduledSearchParams? params;
  final double estTotal;
  final double serviceFee;
  final bool priceFromSearch;

  const _Step3Card({
    required this.profile,
    required this.params,
    required this.estTotal,
    required this.serviceFee,
    required this.priceFromSearch,
  });

  @override
  Widget build(BuildContext context) {
    final h = (params?.durationInMinutes ?? 240) / 60;
    final hoursLabel = h % 1 == 0 ? '${h.toInt()}' : h.toStringAsFixed(1);
    final guideLabel = priceFromSearch
        ? 'Estimated trip price'
        : 'Guide Fee ($hoursLabel h × EGP ${profile.hourlyRate.toStringAsFixed(0)})';

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x121B237E),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STEP 3: SUMMARY',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: _kMuted,
            ),
          ),
          const SizedBox(height: 16),
          _PriceRow(
            label: guideLabel,
            value: 'EGP ${estTotal.toStringAsFixed(0)}',
          ),
          if (serviceFee > 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                height: 1,
                color: _kOutlineVariant.withValues(alpha: 0.3),
              ),
            ),
            _PriceRow(
              label: 'Logistics & Taxes',
              value: 'EGP ${serviceFee.toStringAsFixed(0)}',
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Container(
              height: 1,
              color: _kOutlineVariant.withValues(alpha: 0.3),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Est.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kOnSurface,
                ),
              ),
              Text(
                'EGP ${(estTotal + serviceFee).toStringAsFixed(0)}',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kNavy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  const _PriceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15,
              color: _kOnSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _kOnSurface,
          ),
        ),
      ],
    );
  }
}

// ── Sticky bottom bar ─────────────────────────────────────────────────────────

class _StickyBottom extends StatelessWidget {
  final double estTotal;
  final String helperFirstName;
  final bool loading;
  final bool canRequest;
  final double bottomPad;
  final VoidCallback? onRequest;

  const _StickyBottom({
    required this.estTotal,
    required this.helperFirstName,
    required this.loading,
    required this.canRequest,
    required this.bottomPad,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 32 + bottomPad),
      decoration: BoxDecoration(
        color: _kSurface.withValues(alpha: 0.97),
        border: Border(
          top: BorderSide(
            color: _kOutlineVariant.withValues(alpha: 0.2),
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141B237E),
            blurRadius: 32,
            offset: Offset(0, -12),
          ),
        ],
      ),
      child: Row(
        children: [
          // Est. total
          if (estTotal > 0) ...[
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EST. TOTAL',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    color: _kMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'EGP ${estTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _kOnSurface,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
          ],
          // CTA button
          Expanded(
            child: GestureDetector(
              onTap: onRequest,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient:
                      (canRequest && !loading) ? _kGradient : null,
                  color: (canRequest && !loading)
                      ? null
                      : _kOutlineVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: (canRequest && !loading)
                      ? [
                          BoxShadow(
                            color: _kNavy.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              canRequest
                                  ? 'Request $helperFirstName'
                                  : 'Not Available',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: canRequest
                                    ? Colors.white
                                    : _kMuted.withValues(alpha: 0.6),
                              ),
                            ),
                            if (canRequest) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _ProfileSkeleton extends StatefulWidget {
  final double topPad;
  const _ProfileSkeleton({required this.topPad});

  @override
  State<_ProfileSkeleton> createState() => _ProfileSkeletonState();
}

class _ProfileSkeletonState extends State<_ProfileSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final shimmer = Color.lerp(
          const Color(0xFFE8E6F0),
          const Color(0xFFF5F3FF),
          _ctrl.value,
        )!;
        return Column(
          children: [
            Container(height: 192, color: shimmer),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Container(
                    height: 28,
                    width: 200,
                    decoration: BoxDecoration(
                      color: shimmer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: shimmer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final double topPad;
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.topPad,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Color(0xFFE53935),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                color: _kMuted,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: _kGradient,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
