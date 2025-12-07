import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

class EditProfilePage extends StatefulWidget {
  final UserEntity user;

  const EditProfilePage({
    super.key,
    required this.user,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _userNameController;
  late TextEditingController _phoneController;
  late TextEditingController _countryController;
  String? _selectedGender;
  DateTime? _selectedBirthDate;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _userNameController = TextEditingController(text: widget.user.userName);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _countryController = TextEditingController(text: widget.user.country);
    _selectedGender = widget.user.gender.isNotEmpty ? widget.user.gender : null;
    _selectedBirthDate = widget.user.birthDate;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(
              primary: AppColor.primaryColor, // Use primary color
              onPrimary: Colors.white,
              surface: isDark ? Colors.grey[900]! : Colors.white,
              onSurface: isDark ? Colors.white : Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColor.primaryColor),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedGender == null || _selectedGender!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your gender'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_selectedBirthDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your birth date'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      // Check if userId is not null
      if (widget.user.userId == null || widget.user.userId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User ID is missing'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      context.read<ProfileCubit>().updateProfile(
        userId: widget.user.userId!,
        userName: _userNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        gender: _selectedGender!,
        birthDate: _selectedBirthDate!,
        country: _countryController.text.trim(),
      );
    }
  }

  // Helper for consistent InputDecoration
  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    required bool isDark,
    bool enabled = true,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: enabled
            ? (isDark ? AppColor.primaryColor.withOpacity(0.8) : AppColor.primaryColor)
            : Colors.grey,
      ),
      filled: true,
      fillColor: isDark ? Colors.grey[800] : Colors.grey[50], // Slightly darker fill for dark mode
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColor.primaryColor,
          width: 2,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.grey[850]! : Colors.grey[300]!),
      ),
      labelStyle: TextStyle(
        color: isDark ? Colors.white70 : Colors.black54,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: enabled ? (isDark ? Colors.white : Colors.black) : Colors.grey,
      ),
      decoration: _inputDecoration(
        label: label,
        icon: icon,
        isDark: isDark,
        enabled: enabled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : AppColor.primaryColor, // Matching background
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : AppColor.primaryColor, // Matching AppBar
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white, // Title color is white in both modes to match accounts_settings_page
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white), // Back button color
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isUpdating = state is ProfileUpdating;

          return AnimatedContainer( // Use AnimatedContainer
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Colors.black : Colors.white, // White/Black main body
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Image Section with Tap to Change
                    GestureDetector(
                      onTap: isUpdating ? null : _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: AppColor.primaryColor, // Changed color
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : (widget.user.profileImageUrl != null &&
                                widget.user.profileImageUrl!.isNotEmpty
                                ? NetworkImage(widget.user.profileImageUrl!)
                                : null) as ImageProvider?,
                            child: _selectedImage == null &&
                                (widget.user.profileImageUrl == null ||
                                    widget.user.profileImageUrl!.isEmpty)
                                ? Text(
                              widget.user.userName[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColor.primaryColor, // Use primary color
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? Colors.black : Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to change photo',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Form Fields
                    _buildTextField(
                      controller: _userNameController,
                      label: 'Username',
                      icon: Icons.person,
                      isDark: isDark,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email (Read-only)
                    _buildTextField(
                      controller: TextEditingController(text: widget.user.email),
                      label: 'Email',
                      icon: Icons.email,
                      isDark: isDark,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone,
                      isDark: isDark,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Gender Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      decoration: _inputDecoration(
                        label: 'Gender',
                        icon: Icons.wc,
                        isDark: isDark,
                      ),
                      dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      items: ['Male', 'Female', 'Other']
                          .map((gender) => DropdownMenuItem(
                        value: gender,
                        child: Text(gender),
                      ))
                          .toList(),
                      onChanged: isUpdating ? null : (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your gender';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Birth Date Picker
                    InkWell(
                      onTap: isUpdating ? null : () => _selectDate(context),
                      child: InputDecorator(
                        decoration: _inputDecoration(
                          label: 'Birth Date',
                          icon: Icons.cake,
                          isDark: isDark,
                        ),
                        child: Text(
                          _selectedBirthDate != null
                              ? DateFormat('yyyy-MM-dd').format(_selectedBirthDate!)
                              : 'Select birth date',
                          style: TextStyle(
                            color: _selectedBirthDate != null
                                ? (isDark ? Colors.white : Colors.black)
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _countryController,
                      label: 'Country',
                      icon: Icons.location_on,
                      isDark: isDark,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your country';
                        }
                        return null;
                      },
                    ),

                    Spacer(),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isUpdating ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primaryColor, // Use primary color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isUpdating
                            ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}