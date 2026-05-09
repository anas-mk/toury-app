import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/di/injection_container.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../domain/entities/instant_search_request.dart';
import '../../cubits/instant_booking_cubit.dart';
import '../../cubits/instant_booking_state.dart';
import '../../widgets/instant/duration_picker_sheet.dart';
import '../../widgets/instant/language_picker_sheet.dart';
import 'location_label_format.dart';
import 'location_pick_result.dart';
import 'location_picker_page.dart';

// HTML secondary color: #924C00 (dark amber used for FROM dot)
const Color _kSecondary = Color(0xFF924C00);

class InstantTripDetailsPage extends StatelessWidget {
  const InstantTripDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<InstantBookingCubit>(),
      child: const _View(),
    );
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  LocationPickResult? _pickup;
  LocationPickResult? _destination;
  bool _meetAtDestination = false;
  int _durationMinutes = 0;
  int _travelers = 1;
  String? _languageCode;
  bool _requiresCar = false;
  final TextEditingController _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_meetAtDestination) {
      if (_destination == null || _destination!.name.trim().isEmpty) {
        return false;
      }
    } else {
      final pu = _pickup;
      final de = _destination;
      if (pu == null || de == null) return false;
      if (pu.name.trim().isEmpty || de.name.trim().isEmpty) return false;
    }
    if (_durationMinutes < kMinDurationMinutes ||
        _durationMinutes > kMaxDurationMinutes) {
      return false;
    }
    if (_travelers < 1 || _travelers > 20) return false;
    return true;
  }

  Future<void> _pickLocation({required bool isPickup}) async {
    final result = await Navigator.of(context).push<LocationPickResult>(
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(
          title: isPickup ? 'Pick up point' : 'Destination',
          isPickup: isPickup,
          initial: isPickup ? _pickup : _destination,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      if (isPickup) {
        _pickup = result;
      } else {
        _destination = result;
      }
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _pickMeetingPoint() async {
    final result = await Navigator.of(context).push<LocationPickResult>(
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(
          title: 'Meeting point',
          isPickup: false,
          initial: _destination,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _destination = result);
    HapticFeedback.lightImpact();
  }

  void _toggleMeetAtDestination() {
    HapticFeedback.selectionClick();
    setState(() {
      _meetAtDestination = !_meetAtDestination;
      if (_meetAtDestination) _pickup = null;
    });
  }

  void _swapLocations() {
    HapticFeedback.lightImpact();
    setState(() {
      final tmp = _pickup;
      _pickup = _destination;
      _destination = tmp;
    });
  }

  void _showPreferencesSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PreferencesSheet(
        initialDuration: _durationMinutes,
        initialTravelers: _travelers,
        initialLanguage: _languageCode,
        initialCar: _requiresCar,
        onChanged: (duration, language, travelers, car) {
          if (mounted) {
            setState(() {
              _durationMinutes = duration;
              _languageCode = language;
              _travelers = travelers;
              _requiresCar = car;
            });
          }
        },
      ),
    );
  }

  void _onSearchPressed() {
    if (!_canSubmit) {
      HapticFeedback.mediumImpact();
      String msg = 'Please fill in all required fields.';
      if (_meetAtDestination) {
        if (_destination == null) msg = 'Please select a meeting point.';
      } else {
        if (_pickup == null) {
          msg = 'Please select a pickup location.';
        } else if (_destination == null) {
          msg = 'Please select a destination.';
        }
      }
      if (_durationMinutes < kMinDurationMinutes) {
        msg = 'Please set a duration in Travel Preferences.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: BrandTokens.primaryBlueDark,
        ),
      );
      return;
    }
    HapticFeedback.lightImpact();
    _submit();
  }

  void _submit() {
    final effectivePickup = _meetAtDestination ? _destination! : _pickup!;
    final request = InstantSearchRequest(
      pickupLocationName: effectivePickup.name,
      destinationName: _destination!.name,
      destinationLatitude: _destination!.latitude,
      destinationLongitude: _destination!.longitude,
      pickupLatitude: effectivePickup.latitude,
      pickupLongitude: effectivePickup.longitude,
      durationInMinutes: _durationMinutes,
      requestedLanguage: _languageCode,
      requiresCar: _requiresCar,
      travelersCount: _travelers,
    );
    context.read<InstantBookingCubit>().searchHelpers(request);
    context.push(
      AppRouter.instantHelpersList,
      extra: {
        'cubit': context.read<InstantBookingCubit>(),
        'searchRequest': request,
        'pickup': effectivePickup,
        'destination': _destination,
        'travelers': _travelers,
        'durationInMinutes': _durationMinutes,
        'languageCode': _languageCode,
        'requiresCar': _requiresCar,
        'notes':
            _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      },
    );
  }

  String _prefSummary() {
    final duration = _durationMinutes >= kMinDurationMinutes
        ? formatDurationMinutes(_durationMinutes)
        : 'Duration';
    final lang = languageOptionForCode(_languageCode).name;
    final travelers =
        '$_travelers ${_travelers == 1 ? 'Traveler' : 'Travelers'}';
    final car = _requiresCar ? 'Private car' : 'No car';
    return '$duration  •  $lang  •  $travelers  •  $car';
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: BrandTokens.bgSoft,
      body: Stack(
        children: [
          // Wavy background matching the HTML map-pattern
          Positioned.fill(
            child: CustomPaint(painter: _WavyPainter()),
          ),
          Column(
            children: [
              // ── Top App Bar (transparent in HTML)
              _TopBar(
                topPadding: safeTop,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              // ── Main canvas
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Journey card or meeting point card
                      if (_meetAtDestination)
                        _MeetingPointCard(
                          destination: _destination,
                          onPickDestination: _pickMeetingPoint,
                        )
                      else
                        _JourneyCard(
                          pickup: _pickup,
                          destination: _destination,
                          onPickPickup: () => _pickLocation(isPickup: true),
                          onPickDestination: () =>
                              _pickLocation(isPickup: false),
                          onSwap: _swapLocations,
                        ),
                      const SizedBox(height: 16),
                      // Meet at destination toggle chip
                      _MeetAtDestinationToggle(
                        active: _meetAtDestination,
                        onTap: _toggleMeetAtDestination,
                      ),
                      const SizedBox(height: 16),
                      // Preference summarizer
                      _PreferenceSummaryChip(
                        summary: _prefSummary(),
                        onTap: _showPreferencesSheet,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      // ── Bottom action area
      bottomNavigationBar: _BottomActionBar(
        onPressed: () => BlocProvider.of<InstantBookingCubit>(context).state
                is InstantBookingSearching
            ? null
            : _onSearchPressed(),
        isLoading:
            context.watch<InstantBookingCubit>().state is InstantBookingSearching,
      ),
    );
  }
}

// ─── Top App Bar ──────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final double topPadding;
  final VoidCallback onBack;
  const _TopBar({required this.topPadding, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(24, topPadding + 12, 24, 12),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBack,
            child: const Icon(
              Icons.arrow_back_rounded,
              size: 28,
              color: BrandTokens.primaryBlue,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Find a Helper',
            style: BrandTokens.heading(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: BrandTokens.primaryBlue,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Journey Card ─────────────────────────────────────────────────────────────

class _JourneyCard extends StatelessWidget {
  final LocationPickResult? pickup;
  final LocationPickResult? destination;
  final VoidCallback onPickPickup;
  final VoidCallback onPickDestination;
  final VoidCallback onSwap;

  const _JourneyCard({
    required this.pickup,
    required this.destination,
    required this.onPickPickup,
    required this.onPickDestination,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 40,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 80, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── FROM section (dot + line + text in one Row)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: FROM dot + connecting line
                    Column(
                      children: [
                        // FROM circle (32px) with nested 12px solid dot
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _kSecondary.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: _kSecondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Connecting gradient line
                        Container(
                          width: 4,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [_kSecondary, BrandTokens.primaryBlue],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                    const SizedBox(width: 24),
                    // Right: FROM text
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onPickPickup,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _PointLabel('FROM'),
                              const SizedBox(height: 6),
                              Text(
                                pickup == null
                                    ? 'My current location'
                                    : LocationLabel.title(pickup),
                                style: BrandTokens.body(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: BrandTokens.primaryBlue,
                                  height: 1.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // ── TO section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TO circle (32px) with location_on icon
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: BrandTokens.primaryBlue.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: BrandTokens.primaryBlue,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 24),
                    // TO text / placeholder
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onPickDestination,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _PointLabel('TO'),
                              const SizedBox(height: 6),
                              Text(
                                destination == null
                                    ? 'Where are you going?'
                                    : LocationLabel.title(destination),
                                style: BrandTokens.body(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: destination == null
                                      ? BrandTokens.textSecondary
                                          .withValues(alpha: 0.40)
                                      : BrandTokens.primaryBlue,
                                  height: 1.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── Swap button (absolute, vertically centred in card)
          Positioned(
            right: 20,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onSwap,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: BrandTokens.bgSoft,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0C000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.swap_vert_rounded,
                    color: BrandTokens.primaryBlue,
                    size: 20,
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

class _PointLabel extends StatelessWidget {
  final String text;
  const _PointLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: BrandTokens.body(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: BrandTokens.textSecondary,
        height: 1.0,
      ).copyWith(letterSpacing: 2.0),
    );
  }
}

// ─── Preference Summary Chip ──────────────────────────────────────────────────

class _PreferenceSummaryChip extends StatelessWidget {
  final String summary;
  final VoidCallback onTap;
  const _PreferenceSummaryChip({required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: BrandTokens.primaryBlue.withValues(alpha: 0.10),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    summary,
                    style: BrandTokens.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: BrandTokens.primaryBlue,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: BrandTokens.primaryBlue.withValues(alpha: 0.60),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Bottom Action Bar ────────────────────────────────────────────────────────

class _BottomActionBar extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  const _BottomActionBar({required this.onPressed, required this.isLoading});

  @override
  State<_BottomActionBar> createState() => _BottomActionBarState();
}

class _BottomActionBarState extends State<_BottomActionBar> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final safePad = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            BrandTokens.bgSoft,
            BrandTokens.bgSoft.withValues(alpha: 0.90),
            BrandTokens.bgSoft.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, 48, 24, safePad + 32),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) {
          setState(() => _down = false);
          widget.onPressed?.call();
        },
        child: AnimatedScale(
          duration: const Duration(milliseconds: 90),
          scale: _down ? 0.97 : 1.0,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: BrandTokens.primaryBlue,
              borderRadius: BorderRadius.circular(100),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x401B237E),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Search Helpers',
                          style: BrandTokens.heading(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Travel Preferences Bottom Sheet ─────────────────────────────────────────
//
// Stays OPEN after each sub-picker — user sets all prefs then closes manually.

typedef _PrefsCallback = void Function(
    int duration, String? language, int travelers, bool car);

class _PreferencesSheet extends StatefulWidget {
  final int initialDuration;
  final int initialTravelers;
  final String? initialLanguage;
  final bool initialCar;
  final _PrefsCallback onChanged;

  const _PreferencesSheet({
    required this.initialDuration,
    required this.initialTravelers,
    this.initialLanguage,
    required this.initialCar,
    required this.onChanged,
  });

  @override
  State<_PreferencesSheet> createState() => _PreferencesSheetState();
}

class _PreferencesSheetState extends State<_PreferencesSheet> {
  late int _duration;
  late int _travelers;
  late String? _language;
  late bool _car;

  @override
  void initState() {
    super.initState();
    _duration = widget.initialDuration;
    _travelers = widget.initialTravelers;
    _language = widget.initialLanguage;
    _car = widget.initialCar;
  }

  void _notify() =>
      widget.onChanged(_duration, _language, _travelers, _car);

  Future<void> _pickDuration() async {
    final result = await showCustomDurationSheet(
      context,
      initialMinutes: _duration == 0 ? 120 : _duration,
    );
    if (result != null && mounted) {
      setState(() => _duration = result);
      _notify();
    }
  }

  Future<void> _pickLanguage() async {
    final picked =
        await showLanguagePickerSheet(context, initialCode: _language);
    if (picked != null && mounted) {
      setState(() => _language = picked.code);
      _notify();
    }
  }

  Future<void> _pickTravelers() async {
    final count = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _TravelersSheet(value: _travelers),
    );
    if (count != null && mounted) {
      setState(() => _travelers = count);
      _notify();
    }
  }

  void _toggleCar() {
    setState(() => _car = !_car);
    _notify();
  }

  String get _durationLabel => _duration >= kMinDurationMinutes
      ? formatDurationMinutes(_duration)
      : 'Not set';

  String get _languageLabel => languageOptionForCode(_language).name;

  String get _travelersLabel =>
      '$_travelers ${_travelers == 1 ? 'traveler' : 'travelers'}';

  String get _carLabel => _car ? 'Private car' : 'No car needed';

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFF767683).withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Travel Preferences',
                    style: BrandTokens.heading(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: BrandTokens.primaryBlue,
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: BrandTokens.bgSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: BrandTokens.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Divider
          const Divider(height: 1, color: Color(0x1A767683)),
          // Preference rows
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPad + 8),
              child: Column(
                children: [
                  _PrefRow(
                    icon: Icons.schedule_rounded,
                    label: 'Duration',
                    value: _durationLabel,
                    onTap: _pickDuration,
                  ),
                  const Divider(height: 1, color: Color(0x1A767683)),
                  _PrefRow(
                    icon: Icons.language_rounded,
                    label: 'Language',
                    value: _languageLabel,
                    onTap: _pickLanguage,
                  ),
                  const Divider(height: 1, color: Color(0x1A767683)),
                  _PrefRow(
                    icon: Icons.group_rounded,
                    label: 'Travelers',
                    value: _travelersLabel,
                    onTap: _pickTravelers,
                  ),
                  const Divider(height: 1, color: Color(0x1A767683)),
                  _PrefRow(
                    icon: Icons.directions_car_rounded,
                    label: 'Transport',
                    value: _carLabel,
                    onTap: _toggleCar,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrefRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isLast;

  const _PrefRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(
          top: 20,
          bottom: isLast ? 32 : 20,
        ),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: BrandTokens.primaryBlue.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: BrandTokens.primaryBlue, size: 24),
            ),
            const SizedBox(width: 16),
            // Label + value
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: BrandTokens.body(
                      fontSize: 13,
                      color: BrandTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: BrandTokens.heading(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: BrandTokens.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            // Chevron
            Icon(
              Icons.chevron_right_rounded,
              color: BrandTokens.textSecondary.withValues(alpha: 0.40),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Travelers Sheet ──────────────────────────────────────────────────────────

class _TravelersSheet extends StatefulWidget {
  final int value;
  const _TravelersSheet({required this.value});

  @override
  State<_TravelersSheet> createState() => _TravelersSheetState();
}

class _TravelersSheetState extends State<_TravelersSheet> {
  late int _count;

  @override
  void initState() {
    super.initState();
    _count = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPad + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFF767683).withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Text(
            'Number of Travelers',
            style: BrandTokens.heading(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: BrandTokens.primaryBlue,
            ),
          ),
          const SizedBox(height: 36),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepBtn(
                icon: Icons.remove_rounded,
                enabled: _count > 1,
                onTap: () => setState(() => _count--),
              ),
              const SizedBox(width: 40),
              Text(
                '$_count',
                style: BrandTokens.numeric(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  color: BrandTokens.primaryBlue,
                ),
              ),
              const SizedBox(width: 40),
              _StepBtn(
                icon: Icons.add_rounded,
                enabled: _count < 20,
                onTap: () => setState(() => _count++),
              ),
            ],
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _count),
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandTokens.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: Text(
                'Confirm',
                style: BrandTokens.heading(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _StepBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: enabled
              ? BrandTokens.primaryBlue.withValues(alpha: 0.08)
              : BrandTokens.bgSoft,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color:
              enabled ? BrandTokens.primaryBlue : BrandTokens.borderSoft,
          size: 26,
        ),
      ),
    );
  }
}

// ─── Meet at destination toggle chip ─────────────────────────────────────────

class _MeetAtDestinationToggle extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _MeetAtDestinationToggle({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? BrandTokens.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: active
                ? BrandTokens.primaryBlue
                : BrandTokens.borderSoft,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: BrandTokens.primaryBlue.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.group_rounded,
              size: 16,
              color: active ? Colors.white : BrandTokens.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Meet at destination',
              style: BrandTokens.body(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : BrandTokens.textSecondary,
              ),
            ),
            if (active) ...[
              const SizedBox(width: 6),
              const Icon(Icons.close_rounded, size: 14, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Meeting point card (single location, shown when meet-at-destination) ─────

class _MeetingPointCard extends StatelessWidget {
  final LocationPickResult? destination;
  final VoidCallback onPickDestination;

  const _MeetingPointCard({
    required this.destination,
    required this.onPickDestination,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 40,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPickDestination,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 24, 32),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: BrandTokens.primaryBlue.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: BrandTokens.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PointLabel('MEETING POINT'),
                    const SizedBox(height: 6),
                    Text(
                      destination == null
                          ? 'Where are you meeting?'
                          : LocationLabel.title(destination),
                      style: BrandTokens.body(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: destination == null
                            ? BrandTokens.textSecondary.withValues(alpha: 0.40)
                            : BrandTokens.primaryBlue,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: BrandTokens.textSecondary.withValues(alpha: 0.40),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Wavy background (matches HTML bg-map-pattern) ───────────────────────────

class _WavyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1B237E).withValues(alpha: 0.025)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw horizontal wave rows every ~70px vertically
    const rowSpacing = 70.0;
    // Each wave cycle is 120px wide, amplitude 18px
    const cycleW = 120.0;
    const amp = 18.0;

    final rows = (size.height / rowSpacing).ceil() + 1;
    for (int r = 0; r <= rows; r++) {
      final baseY = r * rowSpacing;
      final path = Path();
      bool up = true;
      double x = 0;
      path.moveTo(0, baseY);
      while (x < size.width) {
        final cpX = x + cycleW / 2;
        final cpY = baseY + (up ? -amp : amp);
        final endX = x + cycleW;
        path.quadraticBezierTo(cpX, cpY, endX, baseY);
        x = endX;
        up = !up;
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
