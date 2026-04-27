import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/di/injection_container.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/widgets/hero_header.dart';
import '../../../domain/entities/instant_search_request.dart';
import '../../cubits/instant_booking_cubit.dart';
import '../../cubits/instant_booking_state.dart';
import '../../widgets/instant/duration_picker_sheet.dart';
import '../../widgets/instant/language_picker_sheet.dart';
import 'location_pick_result.dart';
import 'location_picker_page.dart';

/// Step 2 â€” full trip-details form. The "Find available helpers" CTA fires
/// `POST /user/bookings/instant/search` and then pushes the helpers list.
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
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _pickup != null &&
      _destination != null &&
      _durationMinutes >= kMinDurationMinutes &&
      _durationMinutes <= kMaxDurationMinutes &&
      _travelers >= 1 &&
      _travelers <= 20;

  /// Bug 1 fix â€” single source of truth for opening the map picker.
  /// Pushes [LocationPickerPage] and awaits its [LocationPickResult].
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

  void _submit() {
    if (!_isValid) return;
    final request = InstantSearchRequest(
      pickupLocationName: _pickup!.name,
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceLG,
            AppTheme.spaceSM,
            AppTheme.spaceLG,
            AppTheme.spaceLG,
          ),
          child: BlocBuilder<InstantBookingCubit, InstantBookingState>(
            builder: (_, state) {
              return _PrimaryGradientButton(
                label: 'Find available helpers',
                icon: Icons.search_rounded,
                isLoading: state is InstantBookingSearching,
                onTap: _isValid ? _submit : null,
              );
            },
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: false,
            floating: false,
            delegate: HeroSliverHeader(
              title: 'Plan your instant trip',
              subtitle: 'Tell us where you are and where you want to go',
              leadingIcon: Icons.bolt_rounded,
              height: 200,
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -32),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceLG,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LocationsCard(
                      pickup: _pickup,
                      destination: _destination,
                      onPickPickup: () => _pickLocation(isPickup: true),
                      onPickDestination: () => _pickLocation(isPickup: false),
                    ),
                    const SizedBox(height: AppTheme.spaceLG),

                    SectionTitle(
                      'Trip duration',
                      subtitle: 'Pick a preset or set your own',
                    ),
                    const SizedBox(height: AppTheme.spaceSM),
                    _DurationChips(
                      selectedMinutes: _durationMinutes,
                      onPreset: (m) => setState(() => _durationMinutes = m),
                      onCustom: _pickCustomDuration,
                    ),
                    const SizedBox(height: AppTheme.spaceLG),

                    SectionTitle('Travelers', subtitle: '1 to 20'),
                    const SizedBox(height: AppTheme.spaceSM),
                    _TravelerStepper(
                      value: _travelers,
                      onChanged: (v) => setState(() => _travelers = v),
                    ),
                    const SizedBox(height: AppTheme.spaceLG),

                    SectionTitle(
                      'Preferred language',
                      subtitle: 'Optional',
                    ),
                    const SizedBox(height: AppTheme.spaceSM),
                    _LanguageRow(
                      code: _languageCode,
                      onTap: _pickLanguage,
                    ),
                    const SizedBox(height: AppTheme.spaceLG),

                    SectionTitle(
                      'Need a car?',
                      subtitle: 'Helper will drive you',
                    ),
                    const SizedBox(height: AppTheme.spaceSM),
                    _CarSwitchCard(
                      value: _requiresCar,
                      onChanged: (v) => setState(() => _requiresCar = v),
                    ),
                    const SizedBox(height: AppTheme.spaceLG),

                    SectionTitle(
                      'Notes',
                      subtitle: 'Optional, up to 2000 characters',
                    ),
                    const SizedBox(height: AppTheme.spaceSM),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusLG),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(AppTheme.spaceSM),
                      child: TextField(
                        controller: _notesCtrl,
                        minLines: 3,
                        maxLines: 6,
                        maxLength: 2000,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText:
                              'Special requests, accessibility needs, etc.',
                          border: InputBorder.none,
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _LocationsCard extends StatelessWidget {
  final LocationPickResult? pickup;
  final LocationPickResult? destination;
  final VoidCallback onPickPickup;
  final VoidCallback onPickDestination;

  const _LocationsCard({
    required this.pickup,
    required this.destination,
    required this.onPickPickup,
    required this.onPickDestination,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      child: Stack(
        children: [
          Positioned(
            left: AppTheme.spaceMD + 9, // align under the dot
            top: AppTheme.spaceLG + 26,
            bottom: AppTheme.spaceLG + 26,
            child: const _DottedVerticalLine(),
          ),
          Column(
            children: [
              _LocationTile(
                isPickup: true,
                location: pickup,
                placeholder: 'Choose pickup point',
                onTap: onPickPickup,
              ),
              const SizedBox(height: AppTheme.spaceLG),
              _LocationTile(
                isPickup: false,
                location: destination,
                placeholder: 'Choose destination',
                onTap: onPickDestination,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  final bool isPickup;
  final LocationPickResult? location;
  final String placeholder;
  final VoidCallback onTap;

  const _LocationTile({
    required this.isPickup,
    required this.location,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = isPickup ? AppColor.accentColor : AppColor.errorColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceSM),
          color: Colors.transparent,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DotIcon(color: accent),
                const SizedBox(width: AppTheme.spaceMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPickup ? 'PICKUP' : 'DESTINATION',
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.2,
                          color: AppColor.lightTextSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location?.name ?? placeholder,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: location == null
                              ? AppColor.lightTextSecondary
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (location != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '${location!.latitude.toStringAsFixed(5)}, '
                            '${location!.longitude.toStringAsFixed(5)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColor.lightTextSecondary,
                            ),
                          ),
                        ),
                      if (location != null && (location!.address ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            location!.address!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColor.lightTextSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSM),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Icon(
                    Icons.map_rounded,
                    color: accent,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DotIcon extends StatelessWidget {
  final Color color;
  const _DotIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _DottedVerticalLine extends StatelessWidget {
  const _DottedVerticalLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        const dotSize = 3.0;
        const gap = 4.0;
        final total = c.maxHeight;
        final n = (total / (dotSize + gap)).floor();
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            n.clamp(2, 999),
            (_) => Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: AppColor.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DurationChips extends StatelessWidget {
  final int selectedMinutes;
  final ValueChanged<int> onPreset;
  final VoidCallback onCustom;
  const _DurationChips({
    required this.selectedMinutes,
    required this.onPreset,
    required this.onCustom,
  });

  @override
  Widget build(BuildContext context) {
    final isCustom = selectedMinutes != 0 &&
        !kDurationPresetMinutes.contains(selectedMinutes);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final m in kDurationPresetMinutes) ...[
            _DurationChip(
              label: formatDurationMinutes(m),
              selected: selectedMinutes == m,
              onTap: () => onPreset(m),
            ),
            const SizedBox(width: AppTheme.spaceSM),
          ],
          _DurationChip(
            label: isCustom ? formatDurationMinutes(selectedMinutes) : 'Customâ€¦',
            selected: isCustom,
            icon: Icons.tune_rounded,
            onTap: onCustom,
          ),
          const SizedBox(width: AppTheme.spaceXS),
        ],
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback onTap;
  const _DurationChip({
    required this.label,
    required this.selected,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: selected
            ? const LinearGradient(
                colors: [AppColor.accentColor, AppColor.secondaryColor],
              )
            : null,
        color: selected ? null : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: selected ? Colors.transparent : AppColor.lightBorder,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColor.accentColor.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: selected ? Colors.white : AppColor.lightTextSecondary,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColor.lightTextSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TravelerStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _TravelerStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMD,
        vertical: AppTheme.spaceMD,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            enabled: value > 1,
            onTap: () => onChanged(value - 1),
          ),
          Expanded(
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.group_rounded,
                    size: 20,
                    color: AppColor.accentColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$value',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    value == 1 ? 'traveler' : 'travelers',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColor.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            enabled: value < 20,
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
      color: enabled
          ? AppColor.accentColor.withValues(alpha: 0.10)
          : AppColor.lightBorder.withValues(alpha: 0.6),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            color: enabled ? AppColor.accentColor : Colors.grey,
          ),
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final String? code;
  final VoidCallback onTap;
  const _LanguageRow({required this.code, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final option = languageOptionForCode(code);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColor.secondaryColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    option.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Text(
                  option.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (option.code != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceSM,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColor.secondaryColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    option.code!,
                    style: const TextStyle(
                      color: AppColor.secondaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              const SizedBox(width: AppTheme.spaceSM),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarSwitchCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _CarSwitchCard({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMD,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColor.warningColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: AppColor.warningColor,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'I need transportation',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Match only helpers with a car',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColor.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColor.accentColor,
          ),
        ],
      ),
    );
  }
}

class _PrimaryGradientButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isLoading;
  final VoidCallback? onTap;
  const _PrimaryGradientButton({
    required this.label,
    this.icon,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_PrimaryGradientButton> createState() => _PrimaryGradientButtonState();
}

class _PrimaryGradientButtonState extends State<_PrimaryGradientButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.isLoading;
    return AnimatedScale(
      duration: const Duration(milliseconds: 90),
      scale: _down ? 0.98 : 1,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapCancel: enabled ? () => setState(() => _down = false) : null,
          onTapUp: enabled ? (_) => setState(() => _down = false) : null,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              gradient: const LinearGradient(
                colors: [AppColor.accentColor, AppColor.secondaryColor],
              ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppColor.accentColor.withValues(alpha: 0.32),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
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
                              Icon(widget.icon, color: Colors.white, size: 22),
                              const SizedBox(width: 10),
                            ],
                            Text(
                              widget.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
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
