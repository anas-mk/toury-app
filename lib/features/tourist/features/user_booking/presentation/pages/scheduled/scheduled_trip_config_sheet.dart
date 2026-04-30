import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../../core/di/injection_container.dart';
import '../../../../../../../core/services/directions/directions_service.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/theme/brand_typography.dart';
import '../../../../../../../core/widgets/brand/brand_kit.dart';
import '../../../domain/entities/meeting_point_type.dart';
import '../../widgets/scheduled/scheduled_trip_config.dart';

/// Modal bottom sheet that finalises the scheduled-booking config AFTER
/// the user has already locked in destination + (optional) pickup on
/// the search form.
///
/// Backend contract recap (Fix 1):
///   * destinationName + destinationLatitude + destinationLongitude → REQUIRED
///   * pickupLocationName, pickupLatitude, pickupLongitude          → OPTIONAL
///   * meetingPointType                                              → OPTIONAL
///     (Pascal-case wire: "Hotel" | "Airport" | "Custom")
///   * notes (max 2000 chars)                                        → OPTIONAL
///
/// Geo-points are captured up-front in `ScheduledSearchFormScreen` and
/// passed down here as pre-resolved props. This sheet is intentionally
/// narrow now: meeting-point preset + helper notes. Distance estimation
/// (Fix 13) still happens here since it depends on whether the user
/// supplied a pickup pin earlier — which only this sheet's CTA marks as
/// "ready to review".
class ScheduledTripConfigSheet extends StatefulWidget {
  /// Destination label captured on the search form. Read-only here:
  /// editing the destination after seeing helper results would invalidate
  /// the helper match, so we lock it.
  final String destinationName;

  /// Destination geo-point captured on the search form (REQUIRED, in
  /// valid ranges — guaranteed by the form's `_isValid` check).
  final double destinationLatitude;
  final double destinationLongitude;

  /// Optional pickup label captured on the search form. Null if the
  /// user skipped pickup at search time.
  final String? pickupLocationName;
  final double? pickupLatitude;
  final double? pickupLongitude;

  const ScheduledTripConfigSheet({
    super.key,
    required this.destinationName,
    required this.destinationLatitude,
    required this.destinationLongitude,
    this.pickupLocationName,
    this.pickupLatitude,
    this.pickupLongitude,
  });

  @override
  State<ScheduledTripConfigSheet> createState() =>
      _ScheduledTripConfigSheetState();
}

class _ScheduledTripConfigSheetState extends State<ScheduledTripConfigSheet> {
  late final TextEditingController _notesCtrl;

  MeetingPointType _meetingPoint = MeetingPointType.custom;

  // Currently submitting the form (used to disable the CTA while we
  // run the optional Directions request — Fix 13).
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _hasPickupCoords =>
      widget.pickupLatitude != null && widget.pickupLongitude != null;

  Future<void> _submit() async {
    if (_submitting) return;
    HapticFeedback.lightImpact();
    setState(() => _submitting = true);

    // Fix 13: best-effort driving-distance estimate when both pickup
    // and destination coords are available. If it fails (offline,
    // routing service down), we just omit the field — the backend
    // will fall back to its Haversine straight-line approximation.
    double? distanceKm;
    if (_hasPickupCoords) {
      try {
        final directions = sl<DirectionsService>();
        final result = await directions.estimate(
          fromLat: widget.pickupLatitude!,
          fromLng: widget.pickupLongitude!,
          toLat: widget.destinationLatitude,
          toLng: widget.destinationLongitude,
        );
        distanceKm = result?.distanceKm;
      } catch (_) {
        distanceKm = null;
      }
    }

    if (!mounted) return;

    final config = ScheduledTripConfig(
      destinationName: widget.destinationName,
      destinationLatitude: widget.destinationLatitude,
      destinationLongitude: widget.destinationLongitude,
      meetingPointType: _meetingPoint,
      // Fix 3: pickup stays optional. Pass null/null/null when the
      // search form left pickup blank so the create call omits the
      // keys (vs sending zeros, which the backend would treat as a real
      // geo-point on the equator off the coast of West Africa).
      pickupLocationName: widget.pickupLocationName,
      pickupLatitude: widget.pickupLatitude,
      pickupLongitude: widget.pickupLongitude,
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
          'Add anything that\u2019ll help your helper plan the trip.',
          style: BrandTypography.body(color: BrandTokens.textSecondary),
        ),
        const SizedBox(height: 20),

        // ── Trip summary (read-only — set on the search form) ──────────
        _TripSummaryCard(
          destinationName: widget.destinationName,
          destinationLatitude: widget.destinationLatitude,
          destinationLongitude: widget.destinationLongitude,
          pickupLocationName: widget.pickupLocationName,
          pickupLatitude: widget.pickupLatitude,
          pickupLongitude: widget.pickupLongitude,
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
          label: _submitting
              ? 'Calculating distance\u2026'
              : 'Continue to review',
          icon: Icons.arrow_forward_rounded,
          onPressed: _submitting ? null : _submit,
          visualEnabled: !_submitting,
        ),
        const SizedBox(height: 8),
      ],
    );
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

/// Read-only summary of the destination + pickup the user already
/// captured on the search form. Surfaces the coords so the user can
/// sanity-check what was sent. Editing happens by going back to the
/// search form (single source of truth — avoids two pickers in the
/// flow drifting out of sync).
class _TripSummaryCard extends StatelessWidget {
  final String destinationName;
  final double destinationLatitude;
  final double destinationLongitude;
  final String? pickupLocationName;
  final double? pickupLatitude;
  final double? pickupLongitude;

  const _TripSummaryCard({
    required this.destinationName,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.pickupLocationName,
    required this.pickupLatitude,
    required this.pickupLongitude,
  });

  @override
  Widget build(BuildContext context) {
    final hasPickup = pickupLatitude != null && pickupLongitude != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BrandTokens.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(
            icon: Icons.place_rounded,
            iconColor: BrandTokens.primaryBlue,
            label: 'Destination',
            primary: destinationName,
            secondary:
                '${destinationLatitude.toStringAsFixed(5)}, '
                '${destinationLongitude.toStringAsFixed(5)}',
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: BrandTokens.borderSoft),
          const SizedBox(height: 12),
          _SummaryRow(
            icon: hasPickup
                ? Icons.my_location_rounded
                : Icons.location_off_outlined,
            iconColor: hasPickup
                ? BrandTokens.primaryBlue
                : BrandTokens.textMuted,
            label: 'Pickup',
            primary: hasPickup
                ? (pickupLocationName?.isNotEmpty == true
                    ? pickupLocationName!
                    : 'Pinned location')
                : 'Not set — you can add it later via chat',
            secondary: hasPickup
                ? '${pickupLatitude!.toStringAsFixed(5)}, '
                    '${pickupLongitude!.toStringAsFixed(5)}'
                : null,
            muted: !hasPickup,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String primary;
  final String? secondary;
  final bool muted;

  const _SummaryRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.primary,
    required this.secondary,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: BrandTypography.caption(
                  weight: FontWeight.w700,
                  color: BrandTokens.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                primary,
                style: BrandTypography.body(
                  weight: FontWeight.w600,
                  color: muted
                      ? BrandTokens.textMuted
                      : BrandTokens.textPrimary,
                ),
              ),
              if (secondary != null) ...[
                const SizedBox(height: 2),
                Text(
                  secondary!,
                  style: BrandTypography.caption(
                    color: BrandTokens.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
