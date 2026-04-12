import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/widgets/custom_button.dart';
import '../../../../../../../core/widgets/custom_text_field.dart';
import '../../../domain/entities/helper_profile_entity.dart';
import '../../cubit/profile_cubit.dart';
import '../../cubit/profile_state.dart';

class ProfileInfoForm extends StatefulWidget {
  final HelperProfileEntity profile;

  const ProfileInfoForm({
    super.key,
    required this.profile,
  });

  static void show(BuildContext context, HelperProfileEntity profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<ProfileCubit>(),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ProfileInfoForm(profile: profile),
        ),
      ),
    );
  }

  @override
  State<ProfileInfoForm> createState() => _ProfileInfoFormState();
}

class _ProfileInfoFormState extends State<ProfileInfoForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late String _selectedGender;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName);
    _phoneController = TextEditingController(text: widget.profile.phoneNumber);
    _selectedGender = widget.profile.gender.isNotEmpty ? widget.profile.gender : 'MALE';
    _selectedDate = widget.profile.birthDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your birth date')),
        );
        return;
      }
      
      context.read<ProfileCubit>().updateBasicInfo(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        gender: _selectedGender,
        birthDate: _selectedDate!,
      );
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // 18+ requirement generally for helpers
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      child: BlocConsumer<ProfileCubit, ProfileState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == ProfileStatus.success) {
            Navigator.pop(context); // Close bottom sheet on success
          }
        },
        builder: (context, state) {
          final isLoading = state.status == ProfileStatus.updating;

          return Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceLG),
                Text(
                  'Edit Basic Info',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceLG),
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  prefixIcon: Icons.person_outline,
                  enabled: !isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your name';
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spaceMD),
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  enabled: !isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your phone number';
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spaceMD),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: const Icon(Icons.transgender),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'MALE', child: Text('Male')),
                    DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                  ],
                  onChanged: isLoading ? null : (v) => setState(() => _selectedGender = v!),
                ),
                const SizedBox(height: AppTheme.spaceMD),
                InkWell(
                  onTap: isLoading ? null : _pickDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Birth Date',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
                    ),
                    child: Text(
                      _selectedDate == null 
                        ? 'Select Date' 
                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXL),
                CustomButton(
                  text: 'Save Changes',
                  onPressed: _submit,
                  isLoading: isLoading,
                ),
                const SizedBox(height: AppTheme.spaceMD),
              ],
            ),
          );
        },
      ),
    );
  }
}
