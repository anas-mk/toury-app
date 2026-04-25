import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/basic_app_bar.dart';
import '../../../../../../core/widgets/custom_text_field.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/router/app_router.dart';
import '../cubit/helper_auth_cubit.dart';
import '../cubit/helper_auth_state.dart';
import '../widgets/document_picker_widget.dart';

class HelperRegisterPage extends StatefulWidget {
  const HelperRegisterPage({super.key});

  @override
  State<HelperRegisterPage> createState() => _HelperRegisterPageState();
}

class _HelperRegisterPageState extends State<HelperRegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();
  final _formKey4 = GlobalKey<FormState>();
  final _formKey5 = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    context.read<HelperAuthCubit>().initRegistrationData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _userNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  HelperRegistrationData _currentData(BuildContext context) {
    var state = context.read<HelperAuthCubit>().state;
    if (state is HelperAuthRegisterProgress) return state.data;
    return const HelperRegistrationData();
  }

  void _updateData(HelperRegistrationData updated) {
    context.read<HelperAuthCubit>().updateRegistrationData(updated);
  }

  void _goToNextTab() {
    final cubit = context.read<HelperAuthCubit>();
    var data = _currentData(context);
    
    // Step validation checks
    if (data.currentStep == 0) {
      if (!_formKey1.currentState!.validate()) return;
      if (data.birthDate == null) {
        _showError('Please select your birth date');
        return;
      }
      data = data.copyWith(
        email: _emailController.text.trim(),
        fullName: _userNameController.text.trim(),
        password: _passwordController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
      );
    } else if (data.currentStep == 1) {
      if (data.selfieImage == null || data.nationalIdFront == null || data.nationalIdBack == null) {
        _showError('Please upload all required identity documents');
        return;
      }
    } else if (data.currentStep == 2) {
      if (data.criminalRecordFile == null || data.drugTestFile == null) {
        _showError('Please upload all required legal documents');
        return;
      }
    } else if (data.currentStep == 3) {
      if (data.carLicenseFront == null || data.carLicenseBack == null || data.personalLicense == null) {
        _showError('Please upload all required licenses');
        return;
      }
    } else if (data.currentStep == 4) {
      if (data.hasCar) {
        // Basic validation for car fields if needed
      }
    }

    if (data.currentStep < 4) {
      final nextStep = data.currentStep + 1;
      _updateData(data.copyWith(currentStep: nextStep));
      _tabController.animateTo(nextStep);
    } else {
      // Final Submit
      _updateData(data);
      cubit.registerHelper();
    }
  }

  void _goToPreviousTab() {
    var data = _currentData(context);
    if (data.currentStep > 0) {
      final prevStep = data.currentStep - 1;
      _updateData(data.copyWith(currentStep: prevStep));
      _tabController.animateTo(prevStep);
    } else {
      context.pop();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _pickDocument(Function(XFile?) onPicked) async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      onPicked(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E0E0E) : AppColor.primaryColor.withOpacity(0.95),
      appBar: const BasicAppBar(),
      body: SafeArea(
        child: BlocConsumer<HelperAuthCubit, HelperAuthState>(
          listener: (context, state) {
            if (state is HelperAuthError) {
              _showError(state.message);
            } else if (state is HelperAuthEmailVerificationRequired) {
              context.push('${AppRouter.helperLogin}/${AppRouter.helperRegisterVerifyOtp}?email=${Uri.encodeComponent(state.email)}');
            } else if (state is HelperAuthRegistrationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.green),
              );
              
              if (state.action == 'start_onboarding') {
                context.go(AppRouter.helperHome); 
              } else if (state.helper != null || state.action == 'go_to_helper_dashboard') {
                context.go(AppRouter.helperHome);
              }
            }
          },
          builder: (context, state) {
            final data = (state is HelperAuthRegisterProgress)
                ? state.data
                : const HelperRegistrationData();
            final isLoading = state is HelperAuthLoading;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Register as Helper",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Complete 5 steps to create your account",
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),

                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                      ),
                      child: Column(
                        children: [
                          _buildStepIndicator(isDark, data.currentStep),

                          SizedBox(
                            height: 500,
                            child: TabBarView(
                              controller: _tabController,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _buildStep1(isDark, loc, data),
                                _buildStep2(isDark, loc, data),
                                _buildStep3(isDark, loc, data),
                                _buildStep4(isDark, loc, data, isLoading),
                                _buildStep5(isDark, loc, data, isLoading),
                              ],
                            ),
                          ),
                          _buildFooterLinks(theme, isDark),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStepIndicator(bool isDark, int currentStep) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: List.generate(4, (index) {
            final isSelected = currentStep == index;
            final isCompleted = index < currentStep;
            final icons = [
              Icons.person_outline,
              Icons.badge_outlined,
              Icons.gavel_outlined,
              Icons.drive_eta_outlined
            ];
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColor.primaryColor
                      : (isCompleted ? Colors.green : Colors.transparent),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    icons[index],
                    size: 20,
                    color: (isSelected || isCompleted) ? Colors.white : (isDark ? Colors.white38 : Colors.grey),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(bool isLastStep, bool isLoading) {
    return Row(
      children: [
        OutlinedButton(
          onPressed: _goToPreviousTab,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColor.primaryColor,
            side: const BorderSide(color: AppColor.primaryColor),
            minimumSize: const Size(50, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading ? null : _goToNextTab,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    isLastStep ? 'Complete Registration' : 'Next',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep1(bool isDark, AppLocalizations loc, HelperRegistrationData data) {
    // Basic Info
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey1,
        child: SingleChildScrollView(
          child: Column(
            children: [
              CustomTextField(
                hintText: loc.translate("name") ?? "Full Name",
                controller: _userNameController,
                prefixIcon: Icons.person_outline,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                hintText: loc.translate("email") ?? "Email",
                controller: _emailController,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty || !v.contains('@') ? 'Invalid email' : null,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                hintText: loc.translate("password") ?? "Password",
                controller: _passwordController,
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                hintText: loc.translate("phone_number") ?? "Phone Number",
                controller: _phoneNumberController,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              _buildGenderField(isDark, data),
              const SizedBox(height: 14),
              _buildBirthDateField(isDark, data),
              const SizedBox(height: 24),
              _buildNavigationButtons(false, false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep2(bool isDark, AppLocalizations loc, HelperRegistrationData data) {
    // Identity Verification
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey2,
        child: SingleChildScrollView(
          child: Column(
            children: [
              DocumentPickerWidget(
                title: 'Profile Image',
                subtitle: 'A professional profile photo',
                file: data.profileImage,
                onPickPressed: () => _pickDocument((f) => _updateData(data.copyWith(profileImage: f))),
                onRemovePressed: () => _updateData(data.copyWith(profileImage: null)),
              ),
              const SizedBox(height: 16),
              DocumentPickerWidget(
                title: 'Selfie Image',
                subtitle: 'Clear front-facing photo',
                file: data.selfieImage,
                onPickPressed: () => _pickDocument((f) => _updateData(data.copyWith(selfieImage: f))),
                onRemovePressed: () => _updateData(data.copyWith(selfieImage: null)),
              ),
              const SizedBox(height: 16),
              DocumentPickerWidget(
                title: 'National ID (Front)',
                file: data.nationalIdFront,
                onPickPressed: () => _pickDocument((f) => _updateData(data.copyWith(nationalIdFront: f))),
                onRemovePressed: () => _updateData(data.copyWith(nationalIdFront: null)),
              ),
              const SizedBox(height: 16),
              DocumentPickerWidget(
                title: 'National ID (Back)',
                file: data.nationalIdBack,
                onPickPressed: () => _pickDocument((f) => _updateData(data.copyWith(nationalIdBack: f))),
                onRemovePressed: () => _updateData(data.copyWith(nationalIdBack: null)),
              ),
              const SizedBox(height: 24),
              _buildNavigationButtons(false, false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep3(bool isDark, AppLocalizations loc, HelperRegistrationData data) {
    // Legal Documents
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey3,
        child: SingleChildScrollView(
          child: Column(
            children: [
              DocumentPickerWidget(
                title: 'Criminal Record File',
                subtitle: 'Recent background check document',
                file: data.criminalRecordFile,
                onPickPressed: () => _pickDocument((f) => _updateData(data.copyWith(criminalRecordFile: f))),
                onRemovePressed: () => _updateData(data.copyWith(criminalRecordFile: null)),
              ),
              const SizedBox(height: 16),
              DocumentPickerWidget(
                title: 'Drug Test File',
                subtitle: 'Recent drug test results',
                file: data.drugTestFile,
                onPickPressed: () => _pickDocument((f) => _updateData(data.copyWith(drugTestFile: f))),
                onRemovePressed: () => _updateData(data.copyWith(drugTestFile: null)),
              ),
              const SizedBox(height: 24),
              _buildNavigationButtons(false, false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep4(bool isDark, AppLocalizations loc, HelperRegistrationData data, bool isLoading) {
    // Licenses
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey4,
        child: SingleChildScrollView(
          child: Column(
            children: [
              DocumentPickerWidget(
                title: 'Car License (Front)',
                file: data.carLicenseFront,
                onPickPressed: () => _pickDocument((f) => _updateData(data.copyWith(carLicenseFront: f))),
                onRemovePressed: () => _updateData(data.copyWith(carLicenseFront: null)),
              ),
              const SizedBox(height: 16),
              DocumentPickerWidget(
                title: 'Car License (Back)',
                file: data.carLicenseBack,
                onPickPressed: () => _pickDocument((f) => _updateData(data.copyWith(carLicenseBack: f))),
                onRemovePressed: () => _updateData(data.copyWith(carLicenseBack: null)),
              ),
              const SizedBox(height: 16),
              DocumentPickerWidget(
                title: 'Personal Driving License',
                file: data.personalLicense,
                onPickPressed: () => _pickDocument((f) => _updateData(data.copyWith(personalLicense: f))),
                onRemovePressed: () => _updateData(data.copyWith(personalLicense: null)),
              ),
              const SizedBox(height: 24),
              _buildNavigationButtons(true, isLoading),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep5(bool isDark, AppLocalizations loc, HelperRegistrationData data, bool isLoading) {
    // Car Details
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey5,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                title: const Text('Do you have a car?'),
                value: data.hasCar,
                onChanged: (val) => _updateData(data.copyWith(hasCar: val)),
                activeColor: AppColor.primaryColor,
              ),
              if (data.hasCar) ...[
                const SizedBox(height: 16),
                _buildCarDetailsField('Car Brand', data.carBrand, (v) => _updateData(data.copyWith(carBrand: v))),
                const SizedBox(height: 12),
                _buildCarDetailsField('Car Model', data.carModel, (v) => _updateData(data.copyWith(carModel: v))),
                const SizedBox(height: 12),
                _buildCarDetailsField('Car Color', data.carColor, (v) => _updateData(data.copyWith(carColor: v))),
                const SizedBox(height: 12),
                _buildCarDetailsField('License Plate', data.carLicensePlate, (v) => _updateData(data.copyWith(carLicensePlate: v))),
                const SizedBox(height: 12),
                _buildCarDetailsField('Energy Type (e.g. Gas, Electric)', data.carEnergyType, (v) => _updateData(data.copyWith(carEnergyType: v))),
                const SizedBox(height: 12),
                _buildCarDetailsField('Car Type (e.g. SUV, Sedan)', data.carType, (v) => _updateData(data.copyWith(carType: v))),
              ],
              const SizedBox(height: 24),
              _buildNavigationButtons(true, isLoading),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarDetailsField(String label, String value, Function(String) onChanged) {
    return CustomTextField(
      hintText: label,
      onChanged: onChanged,
      prefixIcon: Icons.directions_car_filled_outlined,
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildGenderField(bool isDark, HelperRegistrationData data) {
    return DropdownButtonFormField<String>(
      initialValue: data.gender,
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: Icon(Icons.person_2_outlined, color: isDark ? Colors.white70 : Colors.grey[700]),
        filled: true,
        fillColor: isDark ? Colors.grey[850] : Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      dropdownColor: isDark ? Colors.grey[900] : Colors.white,
      items: const [
        DropdownMenuItem(value: 'Male', child: Text("Male")),
        DropdownMenuItem(value: 'Female', child: Text("Female")),
      ],
      onChanged: (val) {
        if (val != null) _updateData(data.copyWith(gender: val));
      },
    );
  }

  Widget _buildBirthDateField(bool isDark, HelperRegistrationData data) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: data.birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) _updateData(data.copyWith(birthDate: picked));
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Birth Date',
          prefixIcon: Icon(Icons.calendar_month_rounded, color: isDark ? Colors.white70 : Colors.grey[700]),
          filled: true,
          fillColor: isDark ? Colors.grey[850] : Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
        child: Text(
          data.birthDate != null ? '${data.birthDate!.day}/${data.birthDate!.month}/${data.birthDate!.year}' : 'Select birth date',
        ),
      ),
    );
  }

  Widget _buildFooterLinks(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Already have an account?",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          TextButton(
            onPressed: () => context.go(AppRouter.helperLogin),
            child: const Text(
              "Login",
              style: TextStyle(
                color: AppColor.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
