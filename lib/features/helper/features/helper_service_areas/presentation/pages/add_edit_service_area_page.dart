import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/services/haptic_service.dart';
import '../../../../../../core/services/location/mapbox_geocoding_service.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/animations/fade_in_slide.dart';
import '../../../../../../core/widgets/app_loading.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/service_area_entities.dart';
import '../cubit/service_areas_cubit.dart';
import 'map_picker_page.dart';

class AddEditServiceAreaPage extends StatefulWidget {
  final ServiceAreaEntity? existing;

  const AddEditServiceAreaPage({super.key, this.existing});

  @override
  State<AddEditServiceAreaPage> createState() => _AddEditServiceAreaPageState();
}

class _AddEditServiceAreaPageState extends State<AddEditServiceAreaPage> {
  final _formKey = GlobalKey<FormState>();
  final GeocodingService _geo = GeocodingService();

  double _lat = 0;
  double _lng = 0;
  double _radiusKm = 10;
  bool _isPrimary = false;
  bool _locationPicked = false;
  String? _resolvedCity;
  String? _resolvedCountry;
  bool _isResolvingAddress = false;

  static const _radiusOptions = [5, 10, 15, 20];

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _resolvedCountry = e.country;
      _resolvedCity = e.city;
      _lat = e.latitude;
      _lng = e.longitude;
      _radiusKm = _radiusOptions.contains(e.radiusKm.round()) ? e.radiusKm : 10;
      _isPrimary = e.isPrimary;
      _locationPicked = true;
    }
  }

  Future<void> _resolveAddressFromCoordinates() async {
    setState(() => _isResolvingAddress = true);
    try {
      final r = await _geo.reverse(lat: _lat, lng: _lng);
      if (!mounted) return;
      if (r != null) {
        final parts = r.displayName.split(',').map((e) => e.trim()).toList();
        String? city;
        String? country;
        if (parts.length >= 2) {
          country = parts.last;
          city = parts[parts.length - 2];
        } else {
          city = r.name;
          country = 'Egypt';
        }
        setState(() {
          _resolvedCity = city;
          _resolvedCountry = country;
        });
      }
    } catch (e) {
      debugPrint('[ServiceArea] Reverse geocode error: $e');
    } finally {
      if (mounted) setState(() => _isResolvingAddress = false);
    }
  }

  Future<void> _pickOnMap() async {
    HapticService.light();
    final result = await Navigator.of(context).push<Map<String, double>>(
      MaterialPageRoute(
        builder: (_) => MapPickerPage(
          initialLat: _locationPicked ? _lat : null,
          initialLng: _locationPicked ? _lng : null,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _lat = result['lat']!;
        _lng = result['lng']!;
        _locationPicked = true;
        _resolvedCity = null;
        _resolvedCountry = null;
      });
      await _resolveAddressFromCoordinates();
    }
  }

  void _submit(BuildContext context) {
    HapticService.medium();
    if (!_locationPicked) {
      AppSnackbar.show(
        context,
        message: 'Please pick a location on the map first.',
        tone: AppSnackTone.danger,
      );
      return;
    }
    if ((_resolvedCity ?? '').trim().isEmpty ||
        (_resolvedCountry ?? '').trim().isEmpty) {
      AppSnackbar.show(
        context,
        message:
            "Couldn't resolve city/country. Please re-pick the location on the map.",
        tone: AppSnackTone.danger,
      );
      return;
    }

    final entity = ServiceAreaEntity(
      id: widget.existing?.id ?? '',
      country: _resolvedCountry!.trim(),
      city: _resolvedCity!.trim(),
      areaName: null,
      latitude: _lat,
      longitude: _lng,
      radiusKm: _radiusKm,
      isPrimary: _isPrimary,
    );

    final cubit = context.read<ServiceAreasCubit>();
    if (_isEditing) {
      cubit.updateArea(widget.existing!.id, entity);
    } else {
      cubit.addArea(entity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return BlocProvider.value(
      value: sl<ServiceAreasCubit>(),
      child: Scaffold(
        backgroundColor: palette.scaffold,
        body: BlocListener<ServiceAreasCubit, ServiceAreasState>(
          listener: (context, state) {
            if (state is ServiceAreaOperationSuccess) {
              context.pop();
            } else if (state is ServiceAreasError) {
              AppSnackbar.show(
                context,
                message: state.message,
                tone: AppSnackTone.danger,
              );
            }
          },
          child: Form(
            key: _formKey,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _SliverHero(isEditing: _isEditing),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                  sliver: SliverList.list(
                    children: [
                      FadeInSlide(
                        child: _LocationPickerCard(
                          locationPicked: _locationPicked,
                          lat: _lat,
                          lng: _lng,
                          onTap: _pickOnMap,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeInSlide(
                        delay: const Duration(milliseconds: 60),
                        child: _ResolvedLocationCard(
                          city: _resolvedCity,
                          country: _resolvedCountry,
                          isResolving: _isResolvingAddress,
                          locationPicked: _locationPicked,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeInSlide(
                        delay: const Duration(milliseconds: 120),
                        child: _RadiusSelector(
                          options: _radiusOptions,
                          value: _radiusKm,
                          onChanged: (km) {
                            HapticService.light();
                            setState(() => _radiusKm = km.toDouble());
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeInSlide(
                        delay: const Duration(milliseconds: 180),
                        child: _PrimaryToggleCard(
                          value: _isPrimary,
                          onChanged: (v) {
                            HapticService.medium();
                            setState(() => _isPrimary = v);
                          },
                        ),
                      ),
                      const SizedBox(height: 28),
                      BlocBuilder<ServiceAreasCubit, ServiceAreasState>(
                        builder: (context, state) {
                          final isLoading = state is ServiceAreaOperationLoading;
                          return _SubmitButton(
                            isEditing: _isEditing,
                            isLoading: isLoading,
                            onPressed: isLoading ? null : () => _submit(context),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
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

// ──────────────────────────────────────────────────────────────────────────────
//  SLIVER HERO
// ──────────────────────────────────────────────────────────────────────────────

class _SliverHero extends StatelessWidget {
  final bool isEditing;

  const _SliverHero({required this.isEditing});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 170,
      backgroundColor: palette.scaffold,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: palette.textPrimary),
        onPressed: () {
          HapticService.light();
          context.pop();
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(56, 0, 20, 14),
        title: Text(
          isEditing ? 'Edit Region' : 'Add Region',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        background: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      palette.primary.withValues(
                        alpha: palette.isDark ? 0.30 : 0.18,
                      ),
                      const Color(0xFF7B61FF).withValues(
                        alpha: palette.isDark ? 0.18 : 0.08,
                      ),
                      palette.scaffold,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -30,
              right: -30,
              child: _Orb(color: palette.primary, size: 160),
            ),
            Positioned(
              left: 20,
              bottom: 50,
              right: 20,
              child: Text(
                isEditing
                    ? 'Update where you offer services'
                    : 'Add a new region to expand your reach',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final Color color;
  final double size;

  const _Orb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.30),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  LOCATION PICKER CARD
// ──────────────────────────────────────────────────────────────────────────────

class _LocationPickerCard extends StatelessWidget {
  final bool locationPicked;
  final double lat;
  final double lng;
  final VoidCallback onTap;

  const _LocationPickerCard({
    required this.locationPicked,
    required this.lat,
    required this.lng,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    final accent = palette.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: locationPicked
                  ? accent.withValues(alpha: 0.40)
                  : palette.border,
              width: locationPicked ? 1.0 : 0.6,
            ),
            boxShadow: locationPicked
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: palette.isDark ? 0.28 : 0.18),
                      accent.withValues(alpha: palette.isDark ? 0.14 : 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.30),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  locationPicked
                      ? Icons.check_circle_rounded
                      : Icons.add_location_alt_rounded,
                  color: accent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locationPicked ? 'Location Selected' : 'Pick on Map',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      locationPicked
                          ? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'
                          : 'Tap to open the map and pin the area center',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                        fontFamily: locationPicked ? 'monospace' : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: palette.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  RESOLVED LOCATION CARD
// ──────────────────────────────────────────────────────────────────────────────

class _ResolvedLocationCard extends StatelessWidget {
  final String? city;
  final String? country;
  final bool isResolving;
  final bool locationPicked;

  const _ResolvedLocationCard({
    required this.city,
    required this.country,
    required this.isResolving,
    required this.locationPicked,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    final hasCity = (city ?? '').isNotEmpty;
    final hasCountry = (country ?? '').isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceInset,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border, width: 0.6),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_city_rounded,
            color: palette.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: isResolving
                ? Row(
                    children: [
                      const AppSpinner.tiny(),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Resolving city / country…',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: palette.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        !locationPicked
                            ? 'No location yet'
                            : hasCity
                                ? city!
                                : 'City not found',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        !locationPicked
                            ? 'Pick a point on the map to auto-fill'
                            : hasCountry
                                ? country!
                                : 'Country not found',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  RADIUS SELECTOR
// ──────────────────────────────────────────────────────────────────────────────

class _RadiusSelector extends StatelessWidget {
  final List<int> options;
  final double value;
  final ValueChanged<int> onChanged;

  const _RadiusSelector({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Icon(
                Icons.radio_button_checked_rounded,
                color: palette.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Coverage Radius',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '· how far you operate from the pin',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border, width: 0.6),
          ),
          child: Row(
            children: options.map((km) {
              final selected = value == km.toDouble();
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(km),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                palette.primary,
                                const Color(0xFF7B61FF),
                              ],
                            )
                          : null,
                      color: selected ? null : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: palette.primary.withValues(alpha: 0.30),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      '$km km',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: selected ? Colors.white : palette.textSecondary,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  PRIMARY TOGGLE
// ──────────────────────────────────────────────────────────────────────────────

class _PrimaryToggleCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrimaryToggleCard({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    const accent = Color(0xFFFFB020);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? accent.withValues(alpha: 0.45) : palette.border,
          width: value ? 1.0 : 0.6,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: palette.isDark ? 0.28 : 0.18),
                  accent.withValues(alpha: palette.isDark ? 0.14 : 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accent.withValues(alpha: 0.30),
                width: 0.8,
              ),
            ),
            child: const Icon(Icons.star_rounded, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set as Primary Region',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Travelers see your primary region first',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: accent,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  SUBMIT BUTTON
// ──────────────────────────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  final bool isEditing;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _SubmitButton({
    required this.isEditing,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    final disabled = onPressed == null;

    return Opacity(
      opacity: disabled ? 0.7 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              palette.primary,
              const Color(0xFF7B61FF),
            ],
          ),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: palette.primary.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: isLoading
                    ? const AppSpinner.large(color: Colors.white)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isEditing
                                ? Icons.check_circle_rounded
                                : Icons.add_circle_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isEditing ? 'Save Changes' : 'Add Service Region',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
