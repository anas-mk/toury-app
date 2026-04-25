import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../../core/di/injection_container.dart';
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

  double _lat = 25.2048;
  double _lng = 55.2708;
  double _radiusKm = 50;
  bool _isPrimary = false;
  bool _locationPicked = false;

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
      _radiusKm = e.radiusKm;
      _isPrimary = e.isPrimary;
      _locationPicked = true;
    }
  }

  @override
  void dispose() {
    _countryCtrl.dispose();
    _cityCtrl.dispose();
    _areaNameCtrl.dispose();
    super.dispose();
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
    return BlocProvider.value(
      value: sl<ServiceAreasCubit>(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: Text(
            _isEditing ? 'Edit Service Area' : 'Add Service Area',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: BlocListener<ServiceAreasCubit, ServiceAreasState>(
          listener: (context, state) {
            if (state is ServiceAreaOperationSuccess) {
              context.pop();
            } else if (state is ServiceAreasError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: const Color(0xFFFF6B6B)),
              );
            }
          },
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // ── Location Picker Card ───────────────────────────────────────────
                GestureDetector(
                  onTap: _pickOnMap,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F3C),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _locationPicked
                            ? const Color(0xFF6C63FF).withOpacity(0.5)
                            : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _locationPicked ? Icons.location_on_rounded : Icons.add_location_alt_rounded,
                            color: const Color(0xFF6C63FF),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _locationPicked ? 'Location Selected' : 'Pick on Map',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _locationPicked
                                    ? '${_lat.toStringAsFixed(5)}, ${_lng.toStringAsFixed(5)}'
                                    : 'Tap to open map and pin your area center',
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.map_outlined, color: Colors.white24),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Country Field ───────────────────────────────────────────────────
                _FormLabel('Country'),
                const SizedBox(height: 8),
                _PremiumTextField(
                  controller: _countryCtrl,
                  hint: 'e.g. United Arab Emirates',
                  icon: Icons.flag_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Country is required' : null,
                ),
                const SizedBox(height: 20),

                // ── City Field ─────────────────────────────────────────────────────
                _FormLabel('City ⭐ Required'),
                const SizedBox(height: 8),
                _PremiumTextField(
                  controller: _cityCtrl,
                  hint: 'e.g. Dubai',
                  icon: Icons.location_city_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'City is required for matching' : null,
                ),
                const SizedBox(height: 20),

                // ── Area Name Field ────────────────────────────────────────────────
                _FormLabel('Area Name (Optional)'),
                const SizedBox(height: 8),
                _PremiumTextField(
                  controller: _areaNameCtrl,
                  hint: 'e.g. Downtown, Marina, JBR',
                  icon: Icons.area_chart_rounded,
                ),
                const SizedBox(height: 28),

                // ── Radius Slider ──────────────────────────────────────────────────
                _FormLabel('Coverage Radius'),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F3C),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.07)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('1 km', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_radiusKm.round()} km',
                              style: const TextStyle(
                                  color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Text('500 km', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF6C63FF),
                          inactiveTrackColor: Colors.white12,
                          thumbColor: Colors.white,
                          overlayColor: const Color(0xFF6C63FF).withOpacity(0.2),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                        ),
                        child: Slider(
                          value: _radiusKm,
                          min: 1,
                          max: 500,
                          divisions: 499,
                          onChanged: (v) => setState(() => _radiusKm = v),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Primary Toggle ─────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _isPrimary
                        ? const Color(0xFF6C63FF).withOpacity(0.08)
                        : const Color(0xFF1A1F3C),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isPrimary
                          ? const Color(0xFF6C63FF).withOpacity(0.4)
                          : Colors.white.withOpacity(0.07),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFF6C63FF)),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Set as Primary Area',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            SizedBox(height: 2),
                            Text('Travelers see your primary area prominently',
                                style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _isPrimary,
                        onChanged: (v) => setState(() => _isPrimary = v),
                        activeColor: const Color(0xFF6C63FF),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // ── Submit Button ──────────────────────────────────────────────────
                BlocBuilder<ServiceAreasCubit, ServiceAreasState>(
                  builder: (context, state) {
                    final isLoading = state is ServiceAreaOperationLoading;
                    return ElevatedButton(
                      onPressed: isLoading ? null : () => _submit(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        disabledBackgroundColor: const Color(0xFF6C63FF).withOpacity(0.4),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                        shadowColor: const Color(0xFF6C63FF).withOpacity(0.4),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _isEditing ? 'Save Changes' : 'Add Service Area',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    );
                  },
                ),
                const SizedBox(height: 24),
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
    return Text(text,
        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600));
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
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: const Color(0xFF1A1F3C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
