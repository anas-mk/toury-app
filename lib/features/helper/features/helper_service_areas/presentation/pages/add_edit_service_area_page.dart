import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/custom_card.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../domain/entities/service_area_entities.dart';
import '../cubit/service_areas_cubit.dart';
import 'map_picker_page.dart';

import '../../../../../../core/services/location/mapbox_geocoding_service.dart';

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

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _resolveAddressFromCoordinates() async {
    setState(() => _isResolvingAddress = true);
    try {
      final r = await _geo.reverse(lat: _lat, lng: _lng);
      if (!mounted) return;
      if (r != null) {
        // displayName usually contains full address "District, City, Country"
        final parts = r.displayName.split(',').map((e) => e.trim()).toList();
        
        String? city;
        String? country;

        if (parts.length >= 2) {
          country = parts.last;
          // City is usually the second to last part or the one before it
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
      if (!mounted) return;
      setState(() => _isResolvingAddress = false);
    }
  }

  Future<void> _pickOnMap() async {
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
    if (!_locationPicked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick a location on the map'),
          backgroundColor: AppColor.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if ((_resolvedCity ?? '').trim().isEmpty || (_resolvedCountry ?? '').trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not resolve city/country. Please re-pick location on map.'),
          backgroundColor: AppColor.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider.value(
      value: sl<ServiceAreasCubit>(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
          title: Text(_isEditing ? 'Edit Service Area' : 'Add Service Area'),
        ),
        body: BlocListener<ServiceAreasCubit, ServiceAreasState>(
          listener: (context, state) {
            if (state is ServiceAreaOperationSuccess) {
              context.pop();
            } else if (state is ServiceAreasError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColor.errorColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spaceLG),
              children: [
                // ── Location Picker Card ───────────────────────────────────────────
                GestureDetector(
                  onTap: _pickOnMap,
                  child: CustomCard(
                    variant: _locationPicked ? CardVariant.elevated : CardVariant.outlined,
                    padding: const EdgeInsets.all(AppTheme.spaceMD),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spaceSM),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _locationPicked ? Icons.location_on_rounded : Icons.add_location_alt_rounded,
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceMD),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _locationPicked ? 'Location Selected' : 'Pick on Map',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _locationPicked
                                    ? '${_lat.toStringAsFixed(5)}, ${_lng.toStringAsFixed(5)}'
                                    : 'Tap to open map and pin your area center',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.map_outlined,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceLG),
                _ResolvedLocationCard(
                  city: _resolvedCity,
                  country: _resolvedCountry,
                  isResolving: _isResolvingAddress,
                ),
                const SizedBox(height: AppTheme.spaceXL),

                // ── Radius Selector ───────────────────────────────────────────────────
                Text(
                  'Coverage Radius',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXS),
                CustomCard(
                  variant: CardVariant.outlined,
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXS, vertical: AppTheme.spaceMD),
                  child: Row(
                    children: _radiusOptions.map((km) {
                      final selected = _radiusKm == km.toDouble();
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _radiusKm = km.toDouble()),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: selected
                                  ? theme.colorScheme.primary
                                  : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                            ),
                            child: Text(
                              '$km km',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: selected ? (isDark ? Colors.black : Colors.white) : (isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary),
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceLG),

                // ── Primary Toggle ─────────────────────────────────────────────────
                CustomCard(
                  variant: _isPrimary ? CardVariant.elevated : CardVariant.outlined,
                  padding: const EdgeInsets.all(AppTheme.spaceMD),
                  child: Row(
                    children: [
                      Icon(Icons.star_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: AppTheme.spaceMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Set as Primary Area',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Travelers see your primary area prominently',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _isPrimary,
                        onChanged: (v) => setState(() => _isPrimary = v),
                        activeColor: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXL),

                // ── Submit Button ──────────────────────────────────────────────────
                BlocBuilder<ServiceAreasCubit, ServiceAreasState>(
                  builder: (context, state) {
                    final isLoading = state is ServiceAreaOperationLoading;
                    return CustomButton(
                      onPressed: isLoading ? null : () => _submit(context),
                      text: _isEditing ? 'Save Changes' : 'Add Service Area',
                      isLoading: isLoading,
                      isFullWidth: true,
                    );
                  },
                ),
                const SizedBox(height: AppTheme.spaceXL),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResolvedLocationCard extends StatelessWidget {
  final String? city;
  final String? country;
  final bool isResolving;

  const _ResolvedLocationCard({
    required this.city,
    required this.country,
    required this.isResolving,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomCard(
      variant: CardVariant.outlined,
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      child: Row(
        children: [
          Icon(Icons.location_city_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: isResolving
                ? Text(
                    'Resolving city/country from map...',
                    style: theme.textTheme.bodyMedium,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (city ?? '').isEmpty ? 'City not found' : city!,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (country ?? '').isEmpty ? 'Country not found' : country!,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
