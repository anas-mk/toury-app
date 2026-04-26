import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/custom_card.dart';
import '../../../../../../core/widgets/custom_button.dart';
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
  final _countryCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _areaNameCtrl = TextEditingController();

  double _lat = 0;
  double _lng = 0;
  double _radiusKm = 10;
  bool _isPrimary = false;
  bool _locationPicked = false;

  static const _radiusOptions = [5, 10, 15, 20];
  
  static const _cityCoords = {
    'cairo': (lat: 30.0444, lng: 31.2357),
    'alexandria': (lat: 31.2001, lng: 29.9187),
    'dubai': (lat: 25.2048, lng: 55.2708),
    'riyadh': (lat: 24.7136, lng: 46.6753),
    '10th of ramadan': (lat: 30.3065, lng: 31.7420),
  };

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _countryCtrl.text = e.country;
      _cityCtrl.text = e.city;
      _areaNameCtrl.text = e.areaName ?? '';
      _lat = e.latitude;
      _lng = e.longitude;
      _radiusKm = _radiusOptions.contains(e.radiusKm.round()) ? e.radiusKm : 10;
      _isPrimary = e.isPrimary;
      _locationPicked = true;
    }
    _cityCtrl.addListener(_onCityChanged);
  }

  @override
  void dispose() {
    _cityCtrl.removeListener(_onCityChanged);
    _countryCtrl.dispose();
    _cityCtrl.dispose();
    _areaNameCtrl.dispose();
    super.dispose();
  }

  void _onCityChanged() {
    final city = _cityCtrl.text.trim().toLowerCase();
    final coords = _cityCoords[city];
    if (coords != null) {
      setState(() {
        _lat = coords.lat;
        _lng = coords.lng;
        _locationPicked = true;
      });
    }
  }

  Future<void> _pickOnMap() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => MapPickerPage(
          initialLat: _locationPicked ? _lat : null,
          initialLng: _locationPicked ? _lng : null,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _lat = result.latitude;
        _lng = result.longitude;
        _locationPicked = true;
      });
    }
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    if (!_locationPicked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick a location on the map or enter a recognised city name'),
          backgroundColor: AppColor.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final entity = ServiceAreaEntity(
      id: widget.existing?.id ?? '',
      country: _countryCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      areaName: _areaNameCtrl.text.trim().isEmpty ? null : _areaNameCtrl.text.trim(),
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

                // ── Country Field ───────────────────────────────────────────────────
                _FormLabel('Country'),
                const SizedBox(height: AppTheme.spaceXS),
                _PremiumTextField(
                  controller: _countryCtrl,
                  hint: 'e.g. United Arab Emirates',
                  icon: Icons.flag_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Country is required' : null,
                ),
                const SizedBox(height: AppTheme.spaceLG),

                // ── City Field ─────────────────────────────────────────────────────
                _FormLabel('City ⭐ Required'),
                const SizedBox(height: AppTheme.spaceXS),
                _PremiumTextField(
                  controller: _cityCtrl,
                  hint: 'e.g. Dubai',
                  icon: Icons.location_city_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'City is required for matching' : null,
                ),
                const SizedBox(height: AppTheme.spaceLG),

                // ── Area Name Field ────────────────────────────────────────────────
                _FormLabel('Area Name (Optional)'),
                const SizedBox(height: AppTheme.spaceXS),
                _PremiumTextField(
                  controller: _areaNameCtrl,
                  hint: 'e.g. Downtown, Marina, JBR',
                  icon: Icons.area_chart_rounded,
                ),
                const SizedBox(height: AppTheme.spaceXL),

                // ── Radius Selector ───────────────────────────────────────────────────
                _FormLabel('Coverage Radius'),
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

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Text(
      text,
      style: theme.textTheme.labelLarge?.copyWith(
        color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;

  const _PremiumTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}
