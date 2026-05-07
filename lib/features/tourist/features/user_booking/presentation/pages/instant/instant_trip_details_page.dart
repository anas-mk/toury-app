import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/di/injection_container.dart';
import '../../../../../../../core/localization/app_localizations.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/widgets/brand/brand_kit.dart';
import '../../../domain/entities/instant_search_request.dart';
import '../../cubits/instant_booking_cubit.dart';
import '../../cubits/instant_booking_state.dart';
import '../../widgets/instant/duration_picker_sheet.dart';
import '../../widgets/instant/language_picker_sheet.dart';
import 'location_pick_result.dart';
import 'location_picker_page.dart';

/// Step 2 — full trip-details form. The "Find available helpers" CTA fires
/// `POST /user/bookings/instant/search` and then pushes the helpers list.
///
/// Pass #5 — 2026 fintech redesign
/// -------------------------------
/// * Compact mesh hero with stat strip (verified helpers, avg ETA).
/// * "Route" card that looks like a real itinerary timeline, not a form.
/// * Duration as horizontal pill chips with a custom "+" tile.
/// * Travelers stepper with a big tabular number and avatar dots.
/// * Language pill row using the LanguagePicker (emoji safe-Unicode).
/// * Car toggle as a wide gradient surface.
/// * Notes as a soft floating textarea with live char counter.
/// * Floating glass CTA dock at the bottom that stays above the keyboard.
class InstantTripDetailsPage extends StatelessWidget {
  const InstantTripDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<InstantBookingCubit>(),
      child: const _InstantTripDetailsView(),
    );
  }
}

class _InstantTripDetailsView extends StatefulWidget {
  const _InstantTripDetailsView();

  @override
  State<_InstantTripDetailsView> createState() => _InstantTripDetailsViewState();
}

class _InstantTripDetailsViewState extends State<_InstantTripDetailsView> {
  LocationPickResult? _pickup;
  LocationPickResult? _destination;
  int _durationMinutes = 0;
  int _travelers = 1;
  String? _languageCode;
  bool _requiresCar = false;
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController();
    _notesCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final pu = _pickup;
    final de = _destination;
    if (pu == null || de == null) return false;
    if (pu.name.trim().isEmpty || de.name.trim().isEmpty) return false;
    if (_durationMinutes < kMinDurationMinutes ||
        _durationMinutes > kMaxDurationMinutes) {
      return false;
    }
    if (_travelers < 1 || _travelers > 20) return false;
    return true;
  }

  List<String> _missingFields(AppLocalizations loc) {
    final missing = <String>[];
    final pu = _pickup;
    final de = _destination;
    if (pu == null || pu.name.trim().isEmpty) {
      missing.add(loc.bookingReviewPickupLabel);
    }
    if (de == null || de.name.trim().isEmpty) {
      missing.add(loc.bookingReviewDestinationLabel);
    }
    if (_durationMinutes < kMinDurationMinutes ||
        _durationMinutes > kMaxDurationMinutes) {
      missing.add(loc.bookingReviewDuration);
    }
    if (_travelers < 1 || _travelers > 20) {
      missing.add(loc.bookingReviewTravelers);
    }
    return missing;
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

  Future<void> _pickLanguage() async {
    final picked = await showLanguagePickerSheet(
      context,
      initialCode: _languageCode,
    );
    if (picked != null) setState(() => _languageCode = picked.code);
  }

  Future<void> _pickCustomDuration() async {
    final result = await showCustomDurationSheet(
      context,
      initialMinutes: _durationMinutes == 0 ? 240 : _durationMinutes,
    );
    if (result != null) setState(() => _durationMinutes = result);
  }

  void _onFindHelpersPressed() {
    final loc = AppLocalizations.of(context);
    if (!_canSubmit) {
      HapticFeedback.mediumImpact();
      final missing = _missingFields(loc);
      final message = missing.isEmpty
          ? loc.bookingInstantValidationSnackbar
          : '${loc.bookingInstantValidationSnackbar}\n\u2022 ${missing.join('\n\u2022 ')}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
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
    if (!_canSubmit) return;
    final request = InstantSearchRequest(
      pickupLocationName: _pickup!.name,
      destinationName: _destination!.name,
      destinationLatitude: _destination!.latitude,
      destinationLongitude: _destination!.longitude,
      pickupLatitude: _pickup!.latitude,
      pickupLongitude: _pickup!.longitude,
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
        'pickup': _pickup,
        'destination': _destination,
        'travelers': _travelers,
        'durationInMinutes': _durationMinutes,
        'languageCode': _languageCode,
        'requiresCar': _requiresCar,
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final mediaTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: BrandTokens.bgSoft,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: _FloatingCtaDock(
        builder: (_) => BlocBuilder<InstantBookingCubit, InstantBookingState>(
          builder: (_, state) {
            final loading = state is InstantBookingSearching;
            final missing = _missingFields(loc);
            final cta = _PrimaryGradientButton(
              label: loc.bookingInstantFindHelpers,
              icon: Icons.search_rounded,
              isLoading: loading,
              visualEnabled: _canSubmit,
              onTap: loading ? null : _onFindHelpersPressed,
            );
            if (_canSubmit || missing.isEmpty) return cta;
            return Tooltip(
              message:
                  '${loc.bookingInstantValidationSnackbar}\n\u2022 ${missing.join('\n\u2022 ')}',
              triggerMode: TooltipTriggerMode.tap,
              preferBelow: false,
              showDuration: const Duration(seconds: 4),
              child: cta,
            );
          },
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _Hero(
              topPadding: mediaTop,
              title: loc.bookingInstantPlanTitle,
              subtitle: loc.bookingInstantPlanSubtitle,
              onBack: () => Navigator.of(context).maybePop(),
              filledCount: _filledCount(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                _RouteCard(
                  pickup: _pickup,
                  destination: _destination,
                  onPickPickup: () => _pickLocation(isPickup: true),
                  onPickDestination: () => _pickLocation(isPickup: false),
                ),
                const SizedBox(height: 22),
                const _SectionLabel(
                  icon: Icons.schedule_rounded,
                  title: 'How long do you need?',
                  subtitle: 'Pick a preset or set a custom duration',
                ),
                const SizedBox(height: 10),
                _DurationStrip(
                  selectedMinutes: _durationMinutes,
                  onPreset: (m) {
                    HapticFeedback.selectionClick();
                    setState(() => _durationMinutes = m);
                  },
                  onCustom: _pickCustomDuration,
                ),
                const SizedBox(height: 22),
                const _SectionLabel(
                  icon: Icons.groups_2_rounded,
                  title: 'Travelers',
                  subtitle: '1 to 20',
                ),
                const SizedBox(height: 10),
                _TravelersCard(
                  value: _travelers,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _travelers = v);
                  },
                ),
                const SizedBox(height: 22),
                const _SectionLabel(
                  icon: Icons.translate_rounded,
                  title: 'Preferred language',
                  subtitle: 'Optional',
                ),
                const SizedBox(height: 10),
                _LanguagePill(
                  code: _languageCode,
                  onTap: _pickLanguage,
                ),
                const SizedBox(height: 22),
                const _SectionLabel(
                  icon: Icons.directions_car_filled_rounded,
                  title: 'Need a ride?',
                  subtitle: 'Match only helpers with a car',
                ),
                const SizedBox(height: 10),
                _CarToggleCard(
                  value: _requiresCar,
                  onChanged: (v) {
                    HapticFeedback.lightImpact();
                    setState(() => _requiresCar = v);
                  },
                ),
                const SizedBox(height: 22),
                const _SectionLabel(
                  icon: Icons.edit_note_rounded,
                  title: 'Anything else?',
                  subtitle: 'Optional notes for your helper',
                ),
                const SizedBox(height: 10),
                _NotesCard(
                  controller: _notesCtrl,
                  maxLength: 2000,
                ),
                // CTA dock height + safe-area
                const SizedBox(height: 110),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  int _filledCount() {
    var n = 0;
    if (_pickup != null) n++;
    if (_destination != null) n++;
    if (_durationMinutes >= kMinDurationMinutes) n++;
    if (_travelers >= 1) n++;
    return n;
  }
}

// ============================================================================
//  HERO
// ============================================================================

class _Hero extends StatelessWidget {
  final double topPadding;
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final int filledCount;

  const _Hero({
    required this.topPadding,
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.filledCount,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const _HeroBlobClipper(),
      child: SizedBox(
        height: 240 + topPadding,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const RepaintBoundary(child: MeshGradientBackground()),
            // Subtle dim at the bottom edge so the route card below
            // gets visual separation.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    BrandTokens.primaryBlueDark.withValues(alpha: 0.18),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, topPadding + 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _CircleIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: onBack,
                      ),
                      const Spacer(),
                      _ProgressDots(filled: filledCount, total: 4),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: BrandTokens.amberGradient,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: BrandTokens.accentAmber
                                  .withValues(alpha: 0.45),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: BrandTokens.heading(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: BrandTokens.body(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.85),
                                height: 1.35,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBlobClipper extends CustomClipper<Path> {
  const _HeroBlobClipper();
  @override
  Path getClip(Size size) {
    final p = Path();
    p.moveTo(0, 0);
    p.lineTo(size.width, 0);
    p.lineTo(size.width, size.height - 36);
    // gentle organic wave on the bottom
    p.cubicTo(
      size.width * 0.78, size.height,
      size.width * 0.45, size.height - 56,
      size.width * 0.22, size.height - 18,
    );
    p.cubicTo(
      size.width * 0.10, size.height - 2,
      size.width * 0.04, size.height - 14,
      0, size.height - 28,
    );
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final int filled;
  final int total;
  const _ProgressDots({required this.filled, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final on = i < filled;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: on ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: on
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

// ============================================================================
//  SECTION LABEL
// ============================================================================

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionLabel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: BrandTokens.primaryBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: BrandTokens.primaryBlue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: BrandTokens.heading(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              Text(
                subtitle,
                style: BrandTokens.body(fontSize: 12, height: 1.2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
//  ROUTE CARD (timeline-style)
// ============================================================================

class _RouteCard extends StatelessWidget {
  final LocationPickResult? pickup;
  final LocationPickResult? destination;
  final VoidCallback onPickPickup;
  final VoidCallback onPickDestination;
  const _RouteCard({
    required this.pickup,
    required this.destination,
    required this.onPickPickup,
    required this.onPickDestination,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: BrandTokens.cardShadow,
      ),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Column(
        children: [
          _RoutePoint(
            isPickup: true,
            location: pickup,
            placeholder: 'Choose pickup point',
            onTap: onPickPickup,
          ),
          const _RouteConnector(),
          _RoutePoint(
            isPickup: false,
            location: destination,
            placeholder: 'Choose destination',
            onTap: onPickDestination,
          ),
        ],
      ),
    );
  }
}

class _RoutePoint extends StatelessWidget {
  final bool isPickup;
  final LocationPickResult? location;
  final String placeholder;
  final VoidCallback onTap;
  const _RoutePoint({
    required this.isPickup,
    required this.location,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        isPickup ? BrandTokens.successGreen : BrandTokens.dangerRed;
    final label = isPickup ? 'PICKUP' : 'DESTINATION';
    final filled = location != null && location!.name.trim().isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _RouteDot(color: accent, filled: filled),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: BrandTokens.body(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: accent,
                      height: 1.0,
                    ).copyWith(letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    filled ? location!.name : placeholder,
                    style: BrandTokens.heading(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: filled
                          ? BrandTokens.textPrimary
                          : BrandTokens.textSecondary,
                      height: 1.25,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (filled &&
                      (location!.address ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      location!.address!,
                      style: BrandTokens.body(
                        fontSize: 11.5,
                        color: BrandTokens.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                filled ? Icons.edit_location_alt_rounded : Icons.map_rounded,
                color: accent,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteDot extends StatelessWidget {
  final Color color;
  final bool filled;
  const _RouteDot({required this.color, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: filled ? 0.0 : 0.45),
          width: 2,
        ),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: filled
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
          : null,
    );
  }
}

class _RouteConnector extends StatelessWidget {
  const _RouteConnector();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: SizedBox(
        height: 22,
        child: Row(
          children: [
            // dotted line
            SizedBox(
              width: 22,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  4,
                  (_) => Container(
                    width: 2.5,
                    height: 2.5,
                    decoration: const BoxDecoration(
                      color: BrandTokens.borderSoft,
                      shape: BoxShape.circle,
                    ),
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

// ============================================================================
//  DURATION STRIP
// ============================================================================

class _DurationStrip extends StatelessWidget {
  final int selectedMinutes;
  final ValueChanged<int> onPreset;
  final VoidCallback onCustom;

  const _DurationStrip({
    required this.selectedMinutes,
    required this.onPreset,
    required this.onCustom,
  });

  @override
  Widget build(BuildContext context) {
    final isCustom = selectedMinutes != 0 &&
        !kDurationPresetMinutes.contains(selectedMinutes);
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: kDurationPresetMinutes.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          if (i == kDurationPresetMinutes.length) {
            return _DurationCard(
              value: isCustom ? formatDurationMinutes(selectedMinutes) : 'Custom',
              hint: isCustom ? 'tap to edit' : 'choose any',
              icon: Icons.tune_rounded,
              selected: isCustom,
              onTap: onCustom,
            );
          }
          final m = kDurationPresetMinutes[i];
          final selected = !isCustom && selectedMinutes == m;
          return _DurationCard(
            value: _displayValue(m),
            hint: _displayHint(m),
            selected: selected,
            onTap: () => onPreset(m),
          );
        },
      ),
    );
  }

  String _displayValue(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final mm = minutes % 60;
    if (mm == 0) return '${h}h';
    return '${h}h ${mm}m';
  }

  String _displayHint(int minutes) {
    if (minutes <= 60) return 'quick';
    if (minutes <= 180) return 'short';
    if (minutes <= 360) return 'half-day';
    return 'full day';
  }
}

class _DurationCard extends StatelessWidget {
  final String value;
  final String hint;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _DurationCard({
    required this.value,
    required this.hint,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: 84,
      decoration: BoxDecoration(
        gradient: selected ? BrandTokens.amberGradient : null,
        color: selected ? null : BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? Colors.transparent : BrandTokens.borderSoft,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: BrandTokens.accentAmber.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ]
            : BrandTokens.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null)
                  Icon(
                    icon,
                    size: 16,
                    color: selected ? Colors.white : BrandTokens.primaryBlue,
                  ),
                if (icon != null) const SizedBox(height: 2),
                Text(
                  value,
                  style: BrandTokens.numeric(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? Colors.white
                        : BrandTokens.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  hint,
                  style: BrandTokens.body(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.white.withValues(alpha: 0.85)
                        : BrandTokens.textSecondary,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
//  TRAVELERS CARD
// ============================================================================

class _TravelersCard extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _TravelersCard({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: BrandTokens.cardShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          _CircleStepperButton(
            icon: Icons.remove_rounded,
            enabled: value > 1,
            onTap: () => onChanged(value - 1),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$value',
                      style: BrandTokens.numeric(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: BrandTokens.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        value == 1 ? 'traveler' : 'travelers',
                        style: BrandTokens.body(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: BrandTokens.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _TravelerAvatars(count: value.clamp(1, 5)),
              ],
            ),
          ),
          _CircleStepperButton(
            icon: Icons.add_rounded,
            enabled: value < 20,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _TravelerAvatars extends StatelessWidget {
  final int count;
  const _TravelerAvatars({required this.count});

  @override
  Widget build(BuildContext context) {
    const colors = [
      BrandTokens.accentAmber,
      BrandTokens.primaryBlue,
      BrandTokens.successGreen,
      BrandTokens.gradientMeshD,
      BrandTokens.gradientMeshB,
    ];
    return SizedBox(
      height: 18,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < count; i++)
            Positioned(
              left: i * 12.0,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: colors[i % colors.length],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CircleStepperButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _CircleStepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? BrandTokens.primaryBlue : BrandTokens.borderSoft;
    return Material(
      color: enabled
          ? BrandTokens.primaryBlue.withValues(alpha: 0.10)
          : BrandTokens.bgSoft,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

// ============================================================================
//  LANGUAGE PILL
// ============================================================================

class _LanguagePill extends StatelessWidget {
  final String? code;
  final VoidCallback onTap;
  const _LanguagePill({required this.code, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final option = languageOptionForCode(code);
    return Material(
      color: BrandTokens.surfaceWhite,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: BrandTokens.surfaceWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: BrandTokens.cardShadow,
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFE0E7FF),
                        Color(0xFFC7D2FE),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      option.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        option.name,
                        style: BrandTokens.heading(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.code == null
                            ? 'Helpers in any language'
                            : 'ISO ${option.code}',
                        style: BrandTokens.body(
                          fontSize: 12,
                          color: BrandTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: BrandTokens.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
//  CAR TOGGLE
// ============================================================================

class _CarToggleCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _CarToggleCard({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: value
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF7E6),
                  Color(0xFFFFE7BA),
                ],
              )
            : null,
        color: value ? null : BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value
              ? BrandTokens.accentAmber.withValues(alpha: 0.6)
              : BrandTokens.borderSoft,
          width: 1.4,
        ),
        boxShadow: value
            ? [
                BoxShadow(
                  color: BrandTokens.accentAmber.withValues(alpha: 0.20),
                  blurRadius: 20,
                  spreadRadius: -6,
                  offset: const Offset(0, 10),
                ),
              ]
            : BrandTokens.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: value
                        ? BrandTokens.accentAmber
                        : BrandTokens.accentAmber.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.directions_car_filled_rounded,
                    color: value ? Colors.white : BrandTokens.accentAmber,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Helper drives me',
                        style: BrandTokens.heading(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value
                            ? 'On — only car-equipped helpers will appear'
                            : 'Off — show all available helpers',
                        style: BrandTokens.body(
                          fontSize: 12,
                          color: BrandTokens.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: BrandTokens.accentAmber,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
//  NOTES
// ============================================================================

class _NotesCard extends StatelessWidget {
  final TextEditingController controller;
  final int maxLength;
  const _NotesCard({required this.controller, required this.maxLength});

  @override
  Widget build(BuildContext context) {
    final length = controller.text.characters.length;
    return Container(
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BrandTokens.borderSoft),
        boxShadow: BrandTokens.cardShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 6,
            maxLength: maxLength,
            style: BrandTokens.body(
              fontSize: 14,
              color: BrandTokens.textPrimary,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText:
                  'e.g. wheelchair access, kid-friendly, halal food...',
              hintStyle: BrandTokens.body(
                fontSize: 13.5,
                color: BrandTokens.textSecondary.withValues(alpha: 0.7),
              ),
              border: InputBorder.none,
              counterText: '',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 2, bottom: 2),
            child: Text(
              '$length / $maxLength',
              style: BrandTokens.body(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: length >= maxLength
                    ? BrandTokens.dangerRed
                    : BrandTokens.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
//  FLOATING CTA DOCK
// ============================================================================

class _FloatingCtaDock extends StatelessWidget {
  final WidgetBuilder builder;
  const _FloatingCtaDock({required this.builder});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: BrandTokens.surfaceWhite.withValues(alpha: 0.78),
              border: Border(
                top: BorderSide(
                  color: BrandTokens.borderSoft.withValues(alpha: 0.6),
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: builder(context),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
//  PRIMARY GRADIENT BUTTON
// ============================================================================

class _PrimaryGradientButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isLoading;
  final VoidCallback? onTap;
  final bool visualEnabled;

  const _PrimaryGradientButton({
    required this.label,
    this.icon,
    required this.isLoading,
    required this.onTap,
    this.visualEnabled = true,
  });

  @override
  State<_PrimaryGradientButton> createState() => _PrimaryGradientButtonState();
}

class _PrimaryGradientButtonState extends State<_PrimaryGradientButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.isLoading;
    final muted = enabled && !widget.visualEnabled;

    return AnimatedScale(
      duration: const Duration(milliseconds: 90),
      scale: _down ? 0.98 : 1,
      child: Opacity(
        opacity: muted ? 0.55 : 1,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapCancel: enabled ? () => setState(() => _down = false) : null,
          onTapUp: enabled ? (_) => setState(() => _down = false) : null,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [
                  BrandTokens.gradientMeshB,
                  BrandTokens.primaryBlue,
                ],
              ),
              boxShadow: (enabled && widget.visualEnabled)
                  ? [
                      BoxShadow(
                        color: BrandTokens.primaryBlue
                            .withValues(alpha: 0.40),
                        blurRadius: 24,
                        spreadRadius: -4,
                        offset: const Offset(0, 12),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: enabled ? widget.onTap : null,
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
                            if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                color: Colors.white,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                            ],
                            Text(
                              widget.label,
                              style: BrandTokens.heading(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
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
  }
}
