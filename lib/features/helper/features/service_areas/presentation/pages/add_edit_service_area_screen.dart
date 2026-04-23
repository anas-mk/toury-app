import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/basic_app_bar.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/widgets/custom_text_field.dart';
import '../../domain/entities/service_area_entity.dart';
import '../cubit/helper_service_areas_cubit.dart';
import '../cubit/helper_service_areas_state.dart';
import '../widgets/service_area_map_picker.dart';

class AddEditServiceAreaScreen extends StatefulWidget {
  final ServiceAreaEntity? area;

  const AddEditServiceAreaScreen({super.key, this.area});

  @override
  State<AddEditServiceAreaScreen> createState() => _AddEditServiceAreaScreenState();
}

class _AddEditServiceAreaScreenState extends State<AddEditServiceAreaScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _countryController;
  late TextEditingController _cityController;
  late TextEditingController _areaNameController;
  
  double _radiusKm = 25.0;
  LatLng _location = const LatLng(30.0444, 31.2357); // Cairo default
  bool _isPrimary = false;

  @override
  void initState() {
    super.initState();
    _countryController = TextEditingController(text: widget.area?.country ?? 'Egypt');
    _cityController = TextEditingController(text: widget.area?.city ?? '');
    _areaNameController = TextEditingController(text: widget.area?.areaName ?? '');
    
    if (widget.area != null) {
      _radiusKm = widget.area!.radiusKm;
      _location = LatLng(widget.area!.latitude, widget.area!.longitude);
      _isPrimary = widget.area!.isPrimary;
    }
  }

  @override
  void dispose() {
    _countryController.dispose();
    _cityController.dispose();
    _areaNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.area != null;

    return Scaffold(
      appBar: BasicAppBar(
        title: isEditing ? 'Edit Service Area' : 'Add Service Area',
      ),
      body: BlocListener<HelperServiceAreasCubit, HelperServiceAreasState>(
        listener: (context, state) {
          if (state is HelperServiceAreasLoaded) {
            Navigator.pop(context); // Success, go back
          }
          if (state is HelperServiceAreasError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColor.errorColor),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spaceLG),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  label: 'Country',
                  hintText: 'e.g. Egypt',
                  controller: _countryController,
                  validator: (value) => value == null || value.isEmpty ? 'Please enter country' : null,
                ),
                const SizedBox(height: AppTheme.spaceMD),
                CustomTextField(
                  label: 'City',
                  hintText: 'e.g. Cairo',
                  controller: _cityController,
                  validator: (value) => value == null || value.isEmpty ? 'Please enter city' : null,
                ),
                const SizedBox(height: AppTheme.spaceMD),
                CustomTextField(
                  label: 'Area Name (Optional)',
                  hintText: 'e.g. Zamalek',
                  controller: _areaNameController,
                ),
                const SizedBox(height: AppTheme.spaceLG),
                
                Text(
                  'Radius: ${_radiusKm.toInt()} km',
                  style: AppTheme.labelMedium,
                ),
                Slider(
                  value: _radiusKm,
                  min: 1,
                  max: 500,
                  divisions: 499,
                  label: '${_radiusKm.toInt()} km',
                  activeColor: AppColor.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _radiusKm = value;
                    });
                  },
                ),
                
                const SizedBox(height: AppTheme.spaceMD),
                Text(
                  'Pick Location on Map',
                  style: AppTheme.labelMedium,
                ),
                const SizedBox(height: AppTheme.spaceXS),
                ServiceAreaMapPicker(
                  initialLocation: _location,
                  radiusKm: _radiusKm,
                  onLocationChanged: (newLocation) {
                    setState(() {
                      _location = newLocation;
                    });
                  },
                ),
                
                const SizedBox(height: AppTheme.spaceLG),
                SwitchListTile(
                  title: const Text('Primary Service Area'),
                  subtitle: const Text('Only one area can be primary'),
                  value: _isPrimary,
                  activeColor: AppColor.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _isPrimary = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                
                const SizedBox(height: AppTheme.spaceXL),
                BlocBuilder<HelperServiceAreasCubit, HelperServiceAreasState>(
                  builder: (context, state) {
                    final isLoading = state is HelperServiceAreasCreating || state is HelperServiceAreasUpdating;
                    
                    return CustomButton(
                      text: isEditing ? 'Update Area' : 'Create Area',
                      isLoading: isLoading,
                      onPressed: _submit,
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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final area = ServiceAreaEntity(
        id: widget.area?.id ?? '',
        country: _countryController.text.trim(),
        city: _cityController.text.trim(),
        areaName: _areaNameController.text.trim().isEmpty ? null : _areaNameController.text.trim(),
        latitude: _location.latitude,
        longitude: _location.longitude,
        radiusKm: _radiusKm,
        isPrimary: _isPrimary,
      );

      if (widget.area != null) {
        context.read<HelperServiceAreasCubit>().updateServiceArea(widget.area!.id, area);
      } else {
        context.read<HelperServiceAreasCubit>().createServiceArea(area);
      }
    }
  }
}
