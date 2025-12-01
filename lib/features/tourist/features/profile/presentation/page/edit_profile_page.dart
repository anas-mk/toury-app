// // lib/features/profile/presentation/pages/edit_profile_page.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:intl/intl.dart';
// import '../../domain/entities/user_profile_entity.dart';
// import '../cubit/profile_cubit.dart';
// import '../cubit/profile_state.dart';
//
// class EditProfilePage extends StatefulWidget {
//   final UserProfileEntity user;
//
//   const EditProfilePage({
//     super.key,
//     required this.user,
//   });
//
//   @override
//   State<EditProfilePage> createState() => _EditProfilePageState();
// }
//
// class _EditProfilePageState extends State<EditProfilePage> {
//   final _formKey = GlobalKey<FormState>();
//   late TextEditingController _userNameController;
//   late TextEditingController _phoneController;
//   late TextEditingController _countryController;
//   String? _selectedGender;
//   DateTime? _selectedBirthDate;
//
//   @override
//   void initState() {
//     super.initState();
//     _userNameController = TextEditingController(text: widget.user.userName);
//     _phoneController = TextEditingController(text: widget.user.phoneNumber);
//     _countryController = TextEditingController(text: widget.user.country);
//     _selectedGender = widget.user.gender.isNotEmpty ? widget.user.gender : null;
//     _selectedBirthDate = widget.user.birthDate;
//   }
//
//   @override
//   void dispose() {
//     _userNameController.dispose();
//     _phoneController.dispose();
//     _countryController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedBirthDate ?? DateTime(2000),
//       firstDate: DateTime(1900),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null && picked != _selectedBirthDate) {
//       setState(() {
//         _selectedBirthDate = picked;
//       });
//     }
//   }
//
//   void _saveProfile() {
//     if (_formKey.currentState?.validate() ?? false) {
//       context.read<ProfileCubit>().updateProfile(
//         userName: _userNameController.text.trim(),
//         phoneNumber: _phoneController.text.trim(),
//         gender: _selectedGender,
//         birthDate: _selectedBirthDate,
//         country: _countryController.text.trim(),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//
//     return Scaffold(
//       backgroundColor: isDark ? Colors.black : Colors.grey[100],
//       appBar: AppBar(
//         backgroundColor: isDark ? Colors.black : Colors.white,
//         elevation: 0,
//         title: const Text(
//           'Edit Profile',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//       ),
//       body: BlocConsumer<ProfileCubit, ProfileState>(
//         listener: (context, state) {
//           if (state is ProfileUpdateSuccess) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text('Profile updated successfully'),
//                 backgroundColor: Colors.green,
//               ),
//             );
//             Navigator.pop(context);
//           } else if (state is ProfileError) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(state.message),
//                 backgroundColor: Colors.red,
//               ),
//             );
//           }
//         },
//         builder: (context, state) {
//           final isUpdating = state is ProfileUpdating;
//
//           return SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.all(20),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   children: [
//                     // Profile Image Section
//                     Stack(
//                       children: [
//                         CircleAvatar(
//                           radius: 60,
//                           backgroundColor: Colors.grey[300],
//                           backgroundImage: widget.user.profileImageUrl != null &&
//                               widget.user.profileImageUrl!.isNotEmpty
//                               ? NetworkImage(widget.user.profileImageUrl!)
//                               : null,
//                           child: widget.user.profileImageUrl == null ||
//                               widget.user.profileImageUrl!.isEmpty
//                               ? Text(
//                             widget.user.userName[0].toUpperCase(),
//                             style: const TextStyle(
//                               fontSize: 40,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           )
//                               : null,
//                         ),
//                         Positioned(
//                           bottom: 0,
//                           right: 0,
//                           child: Container(
//                             padding: const EdgeInsets.all(8),
//                             decoration: BoxDecoration(
//                               color: Colors.blue,
//                               shape: BoxShape.circle,
//                               border: Border.all(
//                                 color: isDark ? Colors.black : Colors.white,
//                                 width: 3,
//                               ),
//                             ),
//                             child: const Icon(
//                               Icons.camera_alt,
//                               color: Colors.white,
//                               size: 20,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Tap to change photo',
//                       style: TextStyle(
//                         color: isDark ? Colors.grey[400] : Colors.grey[600],
//                         fontSize: 12,
//                       ),
//                     ),
//                     const SizedBox(height: 32),
//
//                     // Form Fields
//                     _buildTextField(
//                       controller: _userNameController,
//                       label: 'Username',
//                       icon: Icons.person,
//                       isDark: isDark,
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter your username';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),
//
//                     // Email (Read-only)
//                     _buildTextField(
//                       controller: TextEditingController(text: widget.user.email),
//                       label: 'Email',
//                       icon: Icons.email,
//                       isDark: isDark,
//                       enabled: false,
//                     ),
//                     const SizedBox(height: 16),
//
//                     _buildTextField(
//                       controller: _phoneController,
//                       label: 'Phone Number',
//                       icon: Icons.phone,
//                       isDark: isDark,
//                       keyboardType: TextInputType.phone,
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter your phone number';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),
//
//                     // Gender Dropdown
//                     DropdownButtonFormField<String>(
//                       value: _selectedGender,
//                       decoration: InputDecoration(
//                         labelText: 'Gender',
//                         prefixIcon: Icon(
//                           Icons.wc,
//                           color: isDark ? Colors.blue[300] : Colors.blue,
//                         ),
//                         filled: true,
//                         fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide.none,
//                         ),
//                       ),
//                       dropdownColor: isDark ? Colors.grey[850] : Colors.white,
//                       items: ['Male', 'Female', 'Other']
//                           .map((gender) => DropdownMenuItem(
//                         value: gender,
//                         child: Text(gender),
//                       ))
//                           .toList(),
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedGender = value;
//                         });
//                       },
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please select your gender';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),
//
//                     // Birth Date Picker
//                     InkWell(
//                       onTap: () => _selectDate(context),
//                       child: InputDecorator(
//                         decoration: InputDecoration(
//                           labelText: 'Birth Date',
//                           prefixIcon: Icon(
//                             Icons.cake,
//                             color: isDark ? Colors.blue[300] : Colors.blue,
//                           ),
//                           filled: true,
//                           fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: BorderSide.none,
//                           ),
//                         ),
//                         child: Text(
//                           _selectedBirthDate != null
//                               ? DateFormat('yyyy-MM-dd').format(_selectedBirthDate!)
//                               : 'Select birth date',
//                           style: TextStyle(
//                             color: _selectedBirthDate != null
//                                 ? (isDark ? Colors.white : Colors.black)
//                                 : Colors.grey,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//
//                     _buildTextField(
//                       controller: _countryController,
//                       label: 'Country',
//                       icon: Icons.location_on,
//                       isDark: isDark,
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter your country';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 32),
//
//                     // Save Button
//                     SizedBox(
//                       width: double.infinity,
//                       height: 50,
//                       child: ElevatedButton(
//                         onPressed: isUpdating ? null : _saveProfile,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.blue,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: isUpdating
//                             ? const SizedBox(
//                           height: 24,
//                           width: 24,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors.white,
//                           ),
//                         )
//                             : const Text(
//                           'Save Changes',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     required bool isDark,
//     bool enabled = true,
//     TextInputType? keyboardType,
//     String? Function(String?)? validator,
//   }) {
//     return TextFormField(
//       controller: controller,
//       enabled: enabled,
//       keyboardType: keyboardType,
//       validator: validator,
//       style: TextStyle(
//         color: enabled ? (isDark ? Colors.white : Colors.black) : Colors.grey,
//       ),
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(
//           icon,
//           color: enabled
//               ? (isDark ? Colors.blue[300] : Colors.blue)
//               : Colors.grey,
//         ),
//         filled: true,
//         fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide.none,
//         ),
//         disabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.grey[300]!),
//         ),
//       ),
//     );
//   }
// }