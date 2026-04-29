import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../../core/di/injection_container.dart';
import '../../../../../../../core/services/directions/directions_service.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/theme/brand_typography.dart';
import '../../../../../../../core/widgets/brand/brand_kit.dart';
import '../../../domain/entities/meeting_point_type.dart';
import '../../widgets/scheduled/scheduled_trip_config.dart';
import '../instant/location_picker_page.dart';
import '../instant/location_pick_result.dart';

/// Modal bottom sheet that collects the FINAL configuration the user
/// supplies before reviewing their scheduled booking.
///
/// Backend contract recap (Fix 1):
///   * destinationName + destinationLatitude + destinationLongitude → REQUIRED
///   * pickupLocationName, pickupLatitude, pickupLongitude          → OPTIONAL
///   * meetingPointType                                              → OPTIONAL
///     (Pascal-case wire: "Hotel" | "Airport" | "Custom")
///   * notes (max 2000 chars)                                        → OPTIONAL
///
/// Pickup remains optional even after we added the destination picker
/// (Fix 3). A user can plan a trip days ahead without knowing their hotel
/// yet, so we never block submission on missing pickup. We DO show an
/// `OptionalHint` explaining the trade-off.
///
/// Returns a [ScheduledTripConfig] via [Navigator.pop] when the user
/// taps "Continue", or `null` if they back out.
class ScheduledTripConfigSheet extends StatefulWidget {
  /// Pre-populates the destination label with the city the user already
  /// typed in the search form. The user can override it after picking the
  /// real destination on the map.
  final String defaultDestinationName;

  const ScheduledTripConfigSheet({
    super.key,
    required this.defaultDestinationName,
  });

  @override
  State<ScheduledTripConfigSheet> createState() =>
      _ScheduledTripConfigSheetState();
}

class _ScheduledTripConfigSheetState extends State<ScheduledTripConfigSheet> {
  late final TextEditingController _destinationCtrl;
  late final TextEditingController _pickupCtrl;
  late final TextEditingController _notesCtrl;

  MeetingPointType _meetingPoint = MeetingPointType.custom;

  // Destination geo-point (REQUIRED before submit).
  double? _destLat;
  double? _destLng;
  String? _destAddress;

  // Pickup geo-point (OPTIONAL — null means "not set yet").
  double? _pickupLat;
  double? _pickupLng;
  String? _pickupAddress;

  // Currently submitting the form (used to disable the CTA while we
  // run the optional Directions request — Fix 13).
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _destinationCtrl =
        TextEditingController(text: widget.defaultDestinationName);
    _pickupCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _destinationCtrl.dispose();
    _pickupCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  /// Backend gates create on destination coords inside valid ranges.
  bool get _destCoordsValid =>
      _destLat != null &&
      _destLng != null &&
      _destLat! >= -90 &&
      _destLat! <= 90 &&
      _destLng! >= -180 &&
      _destLng! <= 180;

  bool get _isValid =>
      _destinationCtrl.text.trim().isNotEmpty && _destCoordsValid;

  Future<void> _pickDestination() async {
    HapticFeedback.selectionClick();
    final initial = _destLat == null || _destLng == null
        ? null
        : LocationPickResult(
            name: _destinationCtrl.text.trim(),
            address: _destAddress,
            latitude: _destLat!,
            longitude: _destLng!,
          );
    final result = await Navigator.of(context).push<LocationPickResult>(
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(
          title: 'Pick destination',
          isPickup: false,
          initial: initial,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _destLat = result.latitude;
      _destLng = result.longitude;
      _destAddress = result.address;
      // Only overwrite the label if the user hadn't typed something
      // custom — they may have a brand-specific name we shouldn't clobber.
      if (_destinationCtrl.text.trim().isEmpty ||
          _destinationCtrl.text.trim() == widget.defaultDestinationName) {
        _destinationCtrl.text = result.name;
      }
    });
  }

  Future<void> _pickPickup() async {
    HapticFeedback.selectionClick();
    final initial = _pickupLat == null || _pickupLng == null
        ? null
        : LocationPickResult(
            name: _pickupCtrl.text.trim(),
            address: _pickupAddress,
            latitude: _pickupLat!,
            longitude: _pickupLng!,
          );
    final result = await Navigator.of(context).push<LocationPickResult>(
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(
          title: 'Pick pickup point',
          isPickup: true,
          initial: initial,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _pickupLat = result.latitude;
      _pickupLng = result.longitude;
      _pickupAddress = result.address;
      if (_pickupCtrl.text.trim().isEmpty) {
        _pickupCtrl.text = result.name;
      }
    });
  }

  void _clearPickup() {
    setState(() {
      _pickupLat = null;
      _pickupLng = null;
      _pickupAddress = null;
      _pickupCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    HapticFeedback.lightImpact();
    setState(() => _submitting = true);

    // Fix 13: best-effort driving-distance estimate when both pickup
    // and destination coords are available. If it fails (offline,
    // routing service down), we just omit the field — the backend
    // will fall back to its Haversine straight-line approximation.
    double? distanceKm;
    if (_pickupLat != null && _pickupLng != null) {
      try {
        final directions = sl<DirectionsService>();
        final result = await directions.estimate(
          fromLat: _pickupLat!,
          fromLng: _pickupLng!,
          toLat: _destLat!,
          toLng: _destLng!,
        );
        distanceKm = result?.distanceKm;
      } catch (_) {
        distanceKm = null;
      }
    }

    if (!mounted) return;

    final pickupName = _pickupCtrl.text.trim();
    final config = ScheduledTripConfig(
      destinationName: _destinationCtrl.text.trim(),
      destinationLatitude: _destLat!,
      destinationLongitude: _destLng!,
      meetingPointType: _meetingPoint,
      // Fix 3: keep pickup truly optional — return null when both name
      // and coords are missing so the review screen omits the keys from
      // the JSON payload (vs sending zeros, which the backend would
      // treat as a real geo-point on the equator off the coast of West
      // Africa — definitely not what the user meant).
      pickupLocationName: pickupName.isEmpty ? null : pickupName,
      pickupLatitude: _pickupLat,
      pickupLongitude: _pickupLng,
      distanceKm: distanceKm,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.of(context).pop(config);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trip details',
          style: BrandTypography.headline(),
        ),
        const SizedBox(height: 4),
        Text(
          'Confirm where you\u2019re going and add anything that\u2019ll '
          'help your helper.',
          style: BrandTypography.body(color: BrandTokens.textSecondary),
        ),
        const SizedBox(height: 20),

        // ── Destination (REQUIRED) ─────────────────────────────────────
        _Field(
          label: 'Destination',
          required: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _destinationCtrl,
                onChanged: (_) => setState(() {}),
                decoration: _decoration(
                  hint: 'e.g. Pyramids of Giza',
                  icon: Icons.place_rounded,
                ),
              ),
              const SizedBox(height: 8),
              _LocationPickButton(
                hasCoords: _destCoordsValid,
                primaryLabel: _destCoordsValid
                    ? 'Change destination on map'
                    : 'Pick destination on map',
                coordsPreview: _destCoordsValid
                    ? '${_destLat!.toStringAsFixed(5)}, '
                        '${_destLng!.toStringAsFixed(5)}'
                    : null,
                onTap: _pickDestination,
              ),
              if (!_destCoordsValid) ...[
                const SizedBox(height: 6),
                _RequiredHint(
                  text: 'We need your destination on the map so the '
                      'helper can plan the trip and we can give you an '
                      'accurate price.',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ── Meeting point (OPTIONAL — defaults to Custom) ──────────────
        _Field(
          label: 'Meeting point',
          // Backend default is "Custom"; nothing breaks if we omit it.
          required: false,
          child: _MeetingPointPicker(
            selected: _meetingPoint,
            onChanged: (v) => setState(() => _meetingPoint = v),
          ),
        ),
        const SizedBox(height: 18),

        // ── Pickup (OPTIONAL — Fix 3 reaffirmed) ───────────────────────
        _Field(
          label: 'Pickup location',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _pickupCtrl,
                onChanged: (_) => setState(() {}),
                decoration: _decoration(
                  hint: 'Hotel name, address\u2026',
                  icon: Icons.my_location_rounded,
                ),
              ),
              const SizedBox(height: 8),
              _LocationPickButton(
                hasCoords:
                    _pickupLat != null && _pickupLng != null,
                primaryLabel: _pickupLat == null
                    ? 'Drop pin on map (optional)'
                    : 'Change pickup pin',
                coordsPreview: _pickupLat == null
                    ? null
                    : '${_pickupLat!.toStringAsFixed(5)}, '
                        '${_pickupLng!.toStringAsFixed(5)}',
                onTap: _pickPickup,
                onClear: _pickupLat != null ? _clearPickup : null,
              ),
              const SizedBox(height: 4),
              OptionalHint(text: _pickupHint()),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ── Notes (OPTIONAL) ───────────────────────────────────────────
        _Field(
          label: 'Notes for the helper',
          child: TextField(
            controller: _notesCtrl,
            maxLines: 3,
            maxLength: 2000,
            decoration: _decoration(
              hint: 'Anything we should know\u2026',
              icon: Icons.sticky_note_2_rounded,
            ),
          ),
        ),
        const SizedBox(height: 8),
        PrimaryGradientButton(
          label: _submitting ? 'Calculating distance\u2026' : 'Continue to review',
          icon: Icons.arrow_forward_rounded,
          onPressed: (_isValid && !_submitting) ? _submit : null,
          visualEnabled: _isValid && !_submitting,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Honest hint copy that depends on the meeting-point selection — but
  /// never gates submission.
  String _pickupHint() {
    switch (_meetingPoint) {
      case MeetingPointType.hotel:
        return 'You can add your hotel later via chat. Adding it now '
            'helps the helper plan and gets you a more accurate price.';
      case MeetingPointType.airport:
        return 'You can share your flight details later via chat. '
            'Adding a pickup pin now sharpens the price estimate.';
      case MeetingPointType.custom:
        return 'You can add a pickup point later via chat. Add it now '
            'for the most accurate price quote.';
    }
  }

  InputDecoration _decoration({required String hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: BrandTypography.body(color: BrandTokens.textMuted),
      filled: true,
      fillColor: BrandTokens.surfaceWhite,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: BrandTokens.textSecondary, size: 20),
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: BrandTokens.borderSoft),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: BrandTokens.borderSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: BrandTokens.primaryBlue,
          width: 1.6,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;

  const _Field({
    required this.label,
    required this.child,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: BrandTypography.body(weight: FontWeight.w600),
            ),
            if (!required) ...[
              const SizedBox(width: 8),
              const OptionalChip(compact: true),
            ],
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _MeetingPointPicker extends StatelessWidget {
  final MeetingPointType selected;
  final ValueChanged<MeetingPointType> onChanged;

  const _MeetingPointPicker({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MeetingPointType.values.map((t) {
        final selectedNow = t == selected;
        IconData icon;
        switch (t) {
          case MeetingPointType.hotel:
            icon = Icons.hotel_rounded;
            break;
          case MeetingPointType.airport:
            icon = Icons.flight_rounded;
            break;
          case MeetingPointType.custom:
            icon = Icons.place_rounded;
            break;
        }
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(t);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selectedNow
                  ? BrandTokens.primaryBlue
                  : BrandTokens.surfaceWhite,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: selectedNow
                    ? BrandTokens.primaryBlue
                    : BrandTokens.borderSoft,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selectedNow ? Colors.white : BrandTokens.textPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  t.label,
                  style: BrandTypography.body(
                    weight: FontWeight.w600,
                    color:
                        selectedNow ? Colors.white : BrandTokens.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Compact button that opens the [LocationPickerPage] and shows the
/// resolved coordinates underneath when present.
class _LocationPickButton extends StatelessWidget {
  final bool hasCoords;
  final String primaryLabel;
  final String? coordsPreview;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _LocationPickButton({
    required this.hasCoords,
    required this.primaryLabel,
    required this.coordsPreview,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: hasCoords
              ? BrandTokens.borderTinted
              : BrandTokens.surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasCoords
                ? BrandTokens.primaryBlue
                : BrandTokens.borderSoft,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasCoords ? Icons.check_circle_rounded : Icons.map_rounded,
              size: 18,
              color: hasCoords
                  ? BrandTokens.primaryBlue
                  : BrandTokens.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    primaryLabel,
                    style: BrandTypography.caption(
                      weight: FontWeight.w700,
                      color: hasCoords
                          ? BrandTokens.primaryBlue
                          : BrandTokens.textPrimary,
                    ),
                  ),
                  if (coordsPreview != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      coordsPreview!,
                      style: BrandTypography.caption(
                        color: BrandTokens.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                tooltip: 'Clear pin',
                onPressed: onClear,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: BrandTokens.textMuted,
                ),
                splashRadius: 18,
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: BrandTokens.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}

/// Inline hint pinned to a REQUIRED field. Visually distinct from
/// [OptionalHint] so users instantly understand the difference.
class _RequiredHint extends StatelessWidget {
  final String text;

  const _RequiredHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: BrandTokens.textSecondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: BrandTypography.caption(
                color: BrandTokens.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
