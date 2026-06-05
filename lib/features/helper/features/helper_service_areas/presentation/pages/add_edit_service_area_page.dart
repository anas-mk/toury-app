import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/services/location/mapbox_geocoding_service.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/theme/brand_typography.dart';
import '../../../../../../core/widgets/animations/fade_in_slide.dart';
import '../../../../../../core/widgets/app_loading.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/service_area_entities.dart';
import '../cubit/service_areas_cubit.dart';
import '../widgets/service_area_coverage_map_picker.dart';

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
    HapticFeedback.selectionClick();
    final result = await ServiceAreaCoverageMapPicker.show(
      context,
      initialLat: _locationPicked ? _lat : null,
      initialLng: _locationPicked ? _lng : null,
      initialRadiusKm: _radiusKm,
    );
    if (result != null) {
      setState(() {
        _lat = result.lat;
        _lng = result.lng;
        _radiusKm = result.radiusKm;
        _locationPicked = true;
        _resolvedCity = null;
        _resolvedCountry = null;
      });
      await _resolveAddressFromCoordinates();
    }
  }

  void _submit(BuildContext context) {
    HapticFeedback.mediumImpact();
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
    return BlocProvider.value(
      value: sl<ServiceAreasCubit>(),
      child: Scaffold(
        backgroundColor: BrandTokens.bgSoft,
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
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: _PageHeader(
                    title: _isEditing ? 'Edit Region' : 'Add Region',
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  sliver: SliverList.list(
                    children: [
                      const _SectionLabel(text: 'Location'),
                      const SizedBox(height: 10),
                      FadeInSlide(
                        child: _LocationPickerCard(
                          locationPicked: _locationPicked,
                          lat: _lat,
                          lng: _lng,
                          radiusKm: _radiusKm,
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
                      const _SectionLabel(text: 'Preferences'),
                      const SizedBox(height: 10),
                      FadeInSlide(
                        delay: const Duration(milliseconds: 120),
                        child: _PrimaryToggleCard(
                          value: _isPrimary,
                          onChanged: (v) {
                            HapticFeedback.mediumImpact();
                            setState(() => _isPrimary = v);
                          },
                        ),
                      ),
                      const SizedBox(height: 28),
                      BlocBuilder<ServiceAreasCubit, ServiceAreasState>(
                        builder: (context, state) {
                          final isLoading =
                              state is ServiceAreaOperationLoading;
                          return _SubmitButton(
                            isEditing: _isEditing,
                            isLoading: isLoading,
                            onPressed:
                                isLoading ? null : () => _submit(context),
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

// ─── Page Header ─────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final String title;

  const _PageHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final canPop = Navigator.of(context).canPop();

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
        child: SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (canPop)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      context.pop();
                    },
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: palette.textPrimary,
                      size: 20,
                    ),
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  ),
                ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: BrandTypography.title(
                  weight: FontWeight.w800,
                ).copyWith(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Label ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: BrandTypography.overline(),
      ),
    );
  }
}

// ─── Location Picker Card ────────────────────────────────────────────────────

class _LocationPickerCard extends StatelessWidget {
  final bool locationPicked;
  final double lat;
  final double lng;
  final double radiusKm;
  final VoidCallback onTap;

  const _LocationPickerCard({
    required this.locationPicked,
    required this.lat,
    required this.lng,
    required this.radiusKm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandTokens.surfaceWhite,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: locationPicked
                  ? BrandTokens.primaryBlue.withValues(alpha: 0.35)
                  : BrandTokens.borderSoft,
            ),
            boxShadow: BrandTokens.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: locationPicked
                      ? BrandTokens.primaryGradient
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFFFB020).withValues(alpha: 0.18),
                            BrandTokens.primaryBlue.withValues(alpha: 0.14),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: locationPicked
                        ? BrandTokens.primaryBlue.withValues(alpha: 0.22)
                        : const Color(0xFFFFB020).withValues(alpha: 0.22),
                    width: 0.6,
                  ),
                ),
                child: Icon(
                  locationPicked
                      ? Icons.check_circle_rounded
                      : Icons.map_rounded,
                  color: locationPicked
                      ? Colors.white
                      : BrandTokens.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locationPicked ? 'Location selected' : 'Pick on map',
                      style: BrandTypography.title(weight: FontWeight.w800)
                          .copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locationPicked
                          ? '${radiusKm.round()} km coverage · ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'
                          : 'Set center and coverage circle on the map',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: BrandTypography.caption(),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: BrandTokens.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Resolved Location Card ──────────────────────────────────────────────────

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
    final hasCity = (city ?? '').isNotEmpty;
    final hasCountry = (country ?? '').isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandTokens.borderSoft),
        boxShadow: BrandTokens.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: BrandTokens.primaryBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_city_rounded,
              color: BrandTokens.primaryBlue,
              size: 22,
            ),
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
                          style: BrandTypography.body(
                            color: BrandTokens.textMuted,
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
                        style: BrandTypography.body(weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        !locationPicked
                            ? 'Pick a point on the map to auto-fill'
                            : hasCountry
                                ? country!
                                : 'Country not found',
                        style: BrandTypography.caption(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Primary Toggle ──────────────────────────────────────────────────────────

class _PrimaryToggleCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrimaryToggleCard({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFFB020);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value
              ? accent.withValues(alpha: 0.40)
              : BrandTokens.borderSoft,
        ),
        boxShadow: BrandTokens.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accent.withValues(alpha: 0.28),
                width: 0.6,
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
                  'Set as primary region',
                  style: BrandTypography.body(weight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Travelers see your primary region first',
                  style: BrandTypography.caption(),
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

// ─── Submit Button ─────────────────────────────────────────────────────────────

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
    final disabled = onPressed == null;

    return Opacity(
      opacity: disabled ? 0.7 : 1.0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: BrandTokens.primaryGradient,
          boxShadow: disabled ? null : BrandTokens.cardShadow,
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
                            isEditing ? 'Save changes' : 'Add region',
                            style: BrandTypography.body(
                              color: Colors.white,
                              weight: FontWeight.w700,
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
