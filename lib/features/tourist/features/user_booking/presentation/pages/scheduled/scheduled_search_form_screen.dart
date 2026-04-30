import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/theme/brand_typography.dart';
import '../../../../../../../core/widgets/brand/brand_kit.dart';
import '../../../domain/entities/search_params.dart';
import '../instant/location_picker_page.dart';
import '../instant/location_pick_result.dart';

/// First step in the Scheduled Trip flow.
///
/// One job per screen: collect the structured search parameters required
/// by `POST /user/bookings/scheduled/search` (city, date, start, duration,
/// language, requiresCar, travelersCount).
class ScheduledSearchFormScreen extends StatefulWidget {
  final String? initialDestination;

  const ScheduledSearchFormScreen({super.key, this.initialDestination});

  @override
  State<ScheduledSearchFormScreen> createState() =>
      _ScheduledSearchFormScreenState();
}

class _ScheduledSearchFormScreenState extends State<ScheduledSearchFormScreen> {
  late final TextEditingController _cityCtrl;
  late final TextEditingController _travelersCtrl;

  DateTime? _date;
  TimeOfDay? _start;
  // Step 30 minutes (Fix 2: backend wants 60..1440 minutes, so 0.5h grain
  // gives users finer control without violating the wire bounds).
  int _durationMinutes = 240;
  String _languageCode = 'en';
  bool _requiresCar = false;
  int _travelers = 1;

  // Destination geo-point. Required by the booking-create call (so we
  // capture it now and carry it through search → results → review →
  // create). The visible city name is what we send on the search body.
  double? _destLat;
  double? _destLng;
  String? _destAddress;

  // Pickup geo-point. Fully optional — the user can plan the trip days
  // ahead and add a hotel/airport pin later via chat.
  double? _pickupLat;
  double? _pickupLng;
  String? _pickupAddress;
  late final TextEditingController _pickupCtrl;

  static const _languages = <(String code, String label)>[
    ('en', 'English'),
    ('ar', 'Arabic'),
    ('fr', 'French'),
    ('es', 'Spanish'),
    ('de', 'German'),
    ('it', 'Italian'),
    ('ru', 'Russian'),
    ('zh', 'Chinese'),
    ('ja', 'Japanese'),
  ];

  @override
  void initState() {
    super.initState();
    _cityCtrl = TextEditingController(text: widget.initialDestination ?? '');
    _travelersCtrl = TextEditingController(text: '1');
    _pickupCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    _travelersCtrl.dispose();
    _pickupCtrl.dispose();
    super.dispose();
  }

  /// Composed local date+time of the trip start, or null when either picker
  /// is missing. Used by [_isInPast] to block past timestamps client-side
  /// (Fix 4) before we hit the backend (which would reject with
  /// "must be future").
  DateTime? get _composedStart {
    if (_date == null || _start == null) return null;
    return DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _start!.hour,
      _start!.minute,
    );
  }

  bool get _isInPast {
    final composed = _composedStart;
    if (composed == null) return false;
    return composed.isBefore(DateTime.now());
  }

  /// Backend create-call rejects bookings without a destination geo-point
  /// in valid ranges. We capture the coords here and keep `_isValid` strict
  /// so the user can never reach the search call without them.
  bool get _destCoordsValid =>
      _destLat != null &&
      _destLng != null &&
      _destLat! >= -90 &&
      _destLat! <= 90 &&
      _destLng! >= -180 &&
      _destLng! <= 180;

  bool get _isValid =>
      _cityCtrl.text.trim().isNotEmpty &&
      _destCoordsValid &&
      _date != null &&
      _start != null &&
      !_isInPast &&
      _durationMinutes >= 60 &&
      _durationMinutes <= 1440 &&
      _travelers >= 1;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    // firstDate is "today" so the user can still book later today; the
    // _isInPast check handles the time-of-day component (Fix 4).
    final today = DateTime(now.year, now.month, now.day);
    final result = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 1)),
      firstDate: today,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: BrandTokens.primaryBlue,
                ),
          ),
          child: child!,
        );
      },
    );
    if (result != null && mounted) {
      setState(() => _date = result);
    }
  }

  /// Opens the fullscreen [LocationPickerPage] for the destination.
  /// Pre-fills the city field with the resolved name when the user
  /// hasn't typed something custom into it yet (so we don't clobber a
  /// brand name like "Pyramids of Giza" with the reverse-geocoded address).
  Future<void> _pickDestination() async {
    HapticFeedback.selectionClick();
    final initial = _destLat == null || _destLng == null
        ? null
        : LocationPickResult(
            name: _cityCtrl.text.trim(),
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
      // Only auto-fill the visible name when the field is empty or still
      // matches the initial-destination prop — otherwise respect user
      // input.
      final current = _cityCtrl.text.trim();
      if (current.isEmpty || current == (widget.initialDestination ?? '')) {
        _cityCtrl.text = result.name;
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

  Future<void> _pickStart() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _start ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: BrandTokens.primaryBlue,
                ),
          ),
          child: child!,
        );
      },
    );
    if (result != null && mounted) {
      setState(() => _start = result);
    }
  }

  void _submit() {
    if (!_isValid) return;
    HapticFeedback.lightImpact();

    // Defense in depth — UI already disables the CTA, but keep the same
    // check before we build the params in case of future regressions.
    if (_isInPast) return;

    // Wire format: "HH:mm:ss".
    final h = _start!.hour.toString().padLeft(2, '0');
    final m = _start!.minute.toString().padLeft(2, '0');
    final pickupName = _pickupCtrl.text.trim();
    final params = ScheduledSearchParams(
      destinationCity: _cityCtrl.text.trim(),
      // Send the trip-day as UTC midnight so the backend receives the
      // calendar day the user selected regardless of their TZ. The actual
      // time-of-day rides on `startTime` ("HH:mm:ss" local-clock).
      requestedDate: DateTime.utc(_date!.year, _date!.month, _date!.day),
      startTime: '$h:$m:00',
      // Fix 2: send minutes (already validated 60..1440 in `_isValid`).
      // Wire conversion is done here in the UI before handing the params
      // to the search/create cubits — no other layer reinterprets it.
      durationInMinutes: _durationMinutes,
      requestedLanguage: _languageCode,
      requiresCar: _requiresCar,
      travelersCount: _travelers,
      // Carry destination coords through the flow — the search call
      // ignores them, but the create call (POST /scheduled) requires
      // them. _isValid guarantees they're populated and in range.
      destinationLatitude: _destLat,
      destinationLongitude: _destLng,
      // Pickup is fully optional. Pass null when fields are empty so
      // the create call can omit the keys from the JSON payload (rather
      // than sending zeros, which the backend would treat as a real
      // geo-point off the West African coast).
      pickupLocationName: pickupName.isEmpty ? null : pickupName,
      pickupLatitude: _pickupLat,
      pickupLongitude: _pickupLng,
    );

    context.push(
      AppRouter.scheduledResults,
      extra: {'params': params},
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      bottomCta: PrimaryGradientButton(
        label: 'Find helpers',
        icon: Icons.travel_explore_rounded,
        onPressed: _isValid ? _submit : null,
        visualEnabled: _isValid,
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: BrandTokens.bgSoft,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: BrandTokens.textPrimary),
            title: Text(
              'Plan your trip',
              style: BrandTypography.title(weight: FontWeight.w700),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            sliver: SliverList.list(
              children: [
                Text(
                  'Tell us where and when, then we\u2019ll match you with helpers '
                  'available for that window.',
                  style: BrandTypography.body(color: BrandTokens.textSecondary),
                ),
                const SizedBox(height: 24),

                // ── Destination (REQUIRED — coords + label) ──────────
                _Field(
                  label: 'Destination',
                  required: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _cityCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: _decoration(
                          hint: 'e.g. Pyramids of Giza, Cairo',
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
                        _InlineError(
                          text:
                              'Tap the map button to mark exactly where you want to go.',
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── Pickup (OPTIONAL) ────────────────────────────────
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
                      const OptionalHint(
                        text: 'You can leave pickup blank and add it '
                            'later via chat. Adding it now sharpens '
                            'the price estimate.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        label: 'Date',
                        required: true,
                        child: _PickerTile(
                          icon: Icons.event_rounded,
                          text: _date == null
                              ? 'Pick a date'
                              : _formatDate(_date!),
                          placeholder: _date == null,
                          onTap: _pickDate,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field(
                        label: 'Start time',
                        required: true,
                        child: _PickerTile(
                          icon: Icons.schedule_rounded,
                          text: _start == null
                              ? 'Pick time'
                              : _start!.format(context),
                          placeholder: _start == null,
                          onTap: _pickStart,
                          hasError: _isInPast,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isInPast) ...[
                  const SizedBox(height: 6),
                  _InlineError(
                    text: 'Trip start is in the past. Pick a future date and time.',
                  ),
                ],
                const SizedBox(height: 18),
                _Field(
                  label: 'Duration',
                  required: true,
                  child: _DurationStepper(
                    minutes: _durationMinutes,
                    onChanged: (v) => setState(() => _durationMinutes = v),
                  ),
                ),
                const SizedBox(height: 18),
                _Field(
                  label: 'Travelers',
                  required: true,
                  child: _TravelersStepper(
                    value: _travelers,
                    onChanged: (v) => setState(() => _travelers = v),
                  ),
                ),
                const SizedBox(height: 18),
                _Field(
                  label: 'Preferred language',
                  required: true,
                  child: _LanguagePicker(
                    selected: _languageCode,
                    items: _languages,
                    onSelected: (code) =>
                        setState(() => _languageCode = code),
                  ),
                ),
                const SizedBox(height: 18),
                _CarToggle(
                  value: _requiresCar,
                  onChanged: (v) => setState(() => _requiresCar = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
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
      border: _border(),
      enabledBorder: _border(),
      focusedBorder: _border(width: 1.6, color: BrandTokens.primaryBlue),
    );
  }

  OutlineInputBorder _border({
    Color color = BrandTokens.borderSoft,
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
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
              style: BrandTypography.body(weight: FontWeight.w600, color: BrandTokens.textPrimary),
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

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool placeholder;
  final VoidCallback onTap;

  /// Renders the tile with a red border / icon to flag a validation error
  /// (Fix 4 — past start time). The tile stays tappable so the user can fix
  /// the value without losing context.
  final bool hasError;

  const _PickerTile({
    required this.icon,
    required this.text,
    required this.placeholder,
    required this.onTap,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: BrandTokens.surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasError ? BrandTokens.dangerRed : BrandTokens.borderSoft,
            width: hasError ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: hasError
                  ? BrandTokens.dangerRed
                  : BrandTokens.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: BrandTypography.body(
                  color: placeholder
                      ? BrandTokens.textMuted
                      : BrandTokens.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: BrandTokens.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline red error pill, used directly under the picker that triggered it.
class _InlineError extends StatelessWidget {
  final String text;

  const _InlineError({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 14,
            color: BrandTokens.dangerRed,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: BrandTypography.caption(color: BrandTokens.dangerRed),
            ),
          ),
        ],
      ),
    );
  }
}

/// Duration stepper with 30-minute granularity (Fix 2).
///
/// Backend wants `durationInMinutes` ∈ [60, 1440]. We expose minutes
/// directly so the UI can never be off-by-an-hour — no hours→minutes
/// conversion happens later in the stack.
class _DurationStepper extends StatelessWidget {
  static const int _stepMinutes = 30;
  static const int _minMinutes = 60;
  static const int _maxMinutes = 720; // 12h trip cap (UX, well under wire 1440)

  final int minutes;
  final ValueChanged<int> onChanged;

  const _DurationStepper({
    required this.minutes,
    required this.onChanged,
  });

  String _formatLabel(int m) {
    final h = m ~/ 60;
    final r = m % 60;
    if (r == 0) return '$h hour${h == 1 ? '' : 's'}';
    if (h == 0) return '${r}m';
    return '${h}h ${r}m';
  }

  @override
  Widget build(BuildContext context) {
    final canDecrement = minutes - _stepMinutes >= _minMinutes;
    final canIncrement = minutes + _stepMinutes <= _maxMinutes;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BrandTokens.borderSoft),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.hourglass_top_rounded,
            color: BrandTokens.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _formatLabel(minutes),
              style: BrandTypography.body(),
            ),
          ),
          _StepperButton(
            icon: Icons.remove_rounded,
            enabled: canDecrement,
            onTap: () => onChanged(minutes - _stepMinutes),
          ),
          const SizedBox(width: 8),
          _StepperButton(
            icon: Icons.add_rounded,
            enabled: canIncrement,
            onTap: () => onChanged(minutes + _stepMinutes),
          ),
        ],
      ),
    );
  }
}

class _TravelersStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _TravelersStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BrandTokens.borderSoft),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.group_rounded,
            color: BrandTokens.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$value traveler${value == 1 ? '' : 's'}',
              style: BrandTypography.body(),
            ),
          ),
          _StepperButton(
            icon: Icons.remove_rounded,
            enabled: value > 1,
            onTap: () => onChanged(value - 1),
          ),
          const SizedBox(width: 8),
          _StepperButton(
            icon: Icons.add_rounded,
            enabled: value < 12,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? BrandTokens.borderTinted : BrandTokens.bgSoft,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onTap();
              }
            : null,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? BrandTokens.primaryBlue
                : BrandTokens.textMuted,
          ),
        ),
      ),
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  final String selected;
  final List<(String, String)> items;
  final ValueChanged<String> onSelected;

  const _LanguagePicker({
    required this.selected,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, i) {
          final code = items[i].$1;
          final label = items[i].$2;
          final selectedNow = code == selected;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelected(code);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
              alignment: Alignment.center,
              child: Text(
                label,
                style: BrandTypography.body(weight: FontWeight.w600, 
                  color: selectedNow ? Colors.white : BrandTokens.textPrimary,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: items.length,
      ),
    );
  }
}

class _CarToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CarToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: BrandTokens.surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BrandTokens.borderSoft),
        ),
        child: Row(
          children: [
            Icon(
              Icons.directions_car_rounded,
              color: value
                  ? BrandTokens.primaryBlue
                  : BrandTokens.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Helper with car',
                    style: BrandTypography.body(weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Only show helpers driving a car for this trip.',
                    style: BrandTypography.caption(
                      color: BrandTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeThumbColor: BrandTokens.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact button row that opens a location picker and surfaces the
/// resolved coordinates underneath when present. Mirrors the same widget
/// used in `ScheduledTripConfigSheet` so both screens look identical.
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
