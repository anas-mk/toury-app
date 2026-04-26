import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_text_field.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/router/app_router.dart';
import '../cubit/helper_auth_cubit.dart';
import '../cubit/helper_auth_state.dart';
import '../widgets/document_picker_widget.dart';

class HelperRegisterPage extends StatefulWidget {
  const HelperRegisterPage({super.key});

  @override
  State<HelperRegisterPage> createState() => _HelperRegisterPageState();
}

class _HelperRegisterPageState extends State<HelperRegisterPage> with SingleTickerProviderStateMixin {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey5 = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
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
      if (data.selfieImage == null || data.nationalIdFront == null) {
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
    }

    if (data.currentStep < 4) {
      final nextStep = data.currentStep + 1;
      _updateData(data.copyWith(currentStep: nextStep));
      _tabController.animateTo(nextStep);
    } else {
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
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _pickDocument(Function(XFile?) onPicked) async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) onPicked(file);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: _goToPreviousTab,
        ),
        backgroundColor: Colors.transparent,
      ),
      body: BlocConsumer<HelperAuthCubit, HelperAuthState>(
        listener: (context, state) {
          if (state is HelperAuthError) {
            _showError(state.message);
          } else if (state is HelperAuthEmailVerificationRequired) {
            context.push('${AppRouter.helperLogin}/${AppRouter.helperRegisterVerifyOtp}?email=${Uri.encodeComponent(state.email)}');
          } else if (state is HelperAuthRegistrationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Registration Successful!"), backgroundColor: Colors.green),
            );
            context.go(AppRouter.helperHome);
          }
        },
        builder: (context, state) {
          final data = (state is HelperAuthRegisterProgress) ? state.data : const HelperRegistrationData();
          final isLoading = state is HelperAuthLoading;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
                child: Column(
                  children: [
                    const SizedBox(height: AppTheme.spaceLG),
                    Text(
                      "Register as Helper",
                      style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spaceSM),
                    Text(
                      "Step ${data.currentStep + 1} of 5",
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spaceXL),
                    _buildStepIndicator(theme, data.currentStep),
                    const SizedBox(height: AppTheme.space2XL),
                  ],
                ),
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1(theme, data),
                    _buildStep2(theme, data),
                    _buildStep3(theme, data),
                    _buildStep4(theme, data, isLoading),
                    _buildStep5(theme, data, isLoading),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(AppTheme.spaceLG),
                child: Column(
                  children: [
                    _buildNavigationButtons(data.currentStep == 4, isLoading),
                    const SizedBox(height: AppTheme.spaceLG),
                    _buildFooterLinks(theme),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData theme, int currentStep) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceSM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      child: Row(
        children: List.generate(5, (index) {
          final isSelected = currentStep == index;
          final isCompleted = index < currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary : (isCompleted ? Colors.green : theme.colorScheme.onSurface.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavigationButtons(bool isLastStep, bool isLoading) {
    return Row(
      children: [
        if (_tabController.index > 0) ...[
          Expanded(
            flex: 1,
            child: CustomButton(
              text: "Back",
              variant: ButtonVariant.outlined,
              onPressed: _goToPreviousTab,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
        ],
        Expanded(
          flex: 2,
          child: CustomButton(
            text: isLastStep ? "Complete Registration" : "Continue",
            onPressed: isLoading ? null : _goToNextTab,
            isLoading: isLoading,
          ),
        ),
      ],
    );
  }

  Widget _buildStep1(ThemeData theme, HelperRegistrationData data) {
    return Form(
      key: _formKey1,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
        child: Column(
          children: [
            CustomTextField(
              label: "Full Name",
              controller: _userNameController,
              prefixIcon: Icons.person_outline,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppTheme.spaceLG),
            EmailTextField(
              controller: _emailController,
              label: "Email Address",
            ),
            const SizedBox(height: AppTheme.spaceLG),
            PasswordTextField(
              controller: _passwordController,
              label: "Password",
            ),
            const SizedBox(height: AppTheme.spaceLG),
            PhoneTextField(
              controller: _phoneNumberController,
              label: "Phone Number",
            ),
            const SizedBox(height: AppTheme.spaceLG),
            _buildBirthDateField(theme, data),
            const SizedBox(height: AppTheme.spaceXL),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2(ThemeData theme, HelperRegistrationData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
      child: Column(
        children: [
          DocumentPickerWidget(
            title: 'Profile Image',
            subtitle: 'A professional profile photo',
            file: data.profileImage,
            onPickPressed: () => _pickDocument((f) => _updateData(data.copyWith(profileImage: f))),
            onRemovePressed: () => _updateData(data.copyWith(profileImage: null)),
          ),
          const SizedBox(height: AppTheme.spaceLG),
          DocumentPickerWidget(
            title: 'Selfie Image',
            subtitle: 'Clear front-facing photo',
            file: data.selfieImage,
            onPickPressed: () => _pickDocument((f) => _updateData(data.copyWith(selfieImage: f))),
            onRemovePressed: () => _updateData(data.copyWith(selfieImage: null)),
          ),
          const SizedBox(height: AppTheme.spaceLG),
          DocumentPickerWidget(
            title: 'National ID (Front)',
            file: data.nationalIdFront,
            onPickPressed: () => _pickDocument((f) => _updateData(data.copyWith(nationalIdFront: f))),
            onRemovePressed: () => _updateData(data.copyWith(nationalIdFront: null)),
          ),
          const SizedBox(height: AppTheme.spaceXL),
        ],
      ),
    );
  }

  Widget _buildStep3(ThemeData theme, HelperRegistrationData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
      child: Column(
        children: [
          DocumentPickerWidget(
            title: 'National ID (Back)',
            file: data.nationalIdBack,
            onPickPressed: () => _pickDocument((f) => _updateData(data.copyWith(nationalIdBack: f))),
            onRemovePressed: () => _updateData(data.copyWith(nationalIdBack: null)),
          ),
          const SizedBox(height: AppTheme.spaceLG),
          DocumentPickerWidget(
            title: 'Criminal Record File',
            subtitle: 'Recent background check document',
            file: data.criminalRecordFile,
            onPickPressed: () => _pickDocument((f) => _updateData(data.copyWith(criminalRecordFile: f))),
            onRemovePressed: () => _updateData(data.copyWith(criminalRecordFile: null)),
          ),
          const SizedBox(height: AppTheme.spaceLG),
          DocumentPickerWidget(
            title: 'Drug Test File',
            subtitle: 'Recent drug test results',
            file: data.drugTestFile,
            onPickPressed: () => _pickDocument((f) => _updateData(data.copyWith(drugTestFile: f))),
            onRemovePressed: () => _updateData(data.copyWith(drugTestFile: null)),
          ),
          const SizedBox(height: AppTheme.spaceXL),
        ],
      ),
    );
  }

  Widget _buildStep4(ThemeData theme, HelperRegistrationData data, bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
      child: Column(
        children: [
          DocumentPickerWidget(
            title: 'Car License (Front)',
            file: data.carLicenseFront,
            onPickPressed: () => _pickDocument((f) => _updateData(data.copyWith(carLicenseFront: f))),
            onRemovePressed: () => _updateData(data.copyWith(carLicenseFront: null)),
          ),
          const SizedBox(height: AppTheme.spaceLG),
          DocumentPickerWidget(
            title: 'Car License (Back)',
            file: data.carLicenseBack,
            onPickPressed: () => _pickDocument((f) => _updateData(data.copyWith(carLicenseBack: f))),
            onRemovePressed: () => _updateData(data.copyWith(carLicenseBack: null)),
          ),
          const SizedBox(height: AppTheme.spaceLG),
          DocumentPickerWidget(
            title: 'Personal Driving License',
            file: data.personalLicense,
            onPickPressed: () => _pickDocument((f) => _updateData(data.copyWith(personalLicense: f))),
            onRemovePressed: () => _updateData(data.copyWith(personalLicense: null)),
          ),
          const SizedBox(height: AppTheme.spaceXL),
        ],
      ),
    );
  }

  Widget _buildStep5(ThemeData theme, HelperRegistrationData data, bool isLoading) {
    return Form(
      key: _formKey5,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
        child: Column(
          children: [
            SwitchListTile(
              title: Text('Do you have a car?', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              value: data.hasCar,
              onChanged: (val) => _updateData(data.copyWith(hasCar: val)),
              activeColor: theme.colorScheme.primary,
              contentPadding: EdgeInsets.zero,
            ),
            if (data.hasCar) ...[
              const SizedBox(height: AppTheme.spaceLG),
              _buildCarDetailsField('Car Brand', data.carBrand, (v) => _updateData(data.copyWith(carBrand: v))),
              const SizedBox(height: AppTheme.spaceLG),
              _buildCarDetailsField('Car Model', data.carModel, (v) => _updateData(data.copyWith(carModel: v))),
              const SizedBox(height: AppTheme.spaceLG),
              _buildCarDetailsField('Car Color', data.carColor, (v) => _updateData(data.copyWith(carColor: v))),
              const SizedBox(height: AppTheme.spaceLG),
              _buildCarDetailsField('License Plate', data.carLicensePlate, (v) => _updateData(data.copyWith(carLicensePlate: v))),
            ],
            const SizedBox(height: AppTheme.spaceXL),
          ],
        ),
      ),
    );
  }

  Widget _buildCarDetailsField(String label, String value, Function(String) onChanged) {
    return CustomTextField(
      label: label,
      onChanged: onChanged,
      prefixIcon: Icons.directions_car_filled_outlined,
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildBirthDateField(ThemeData theme, HelperRegistrationData data) {
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
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: AppTheme.spaceLG),
            Text(
              data.birthDate != null ? '${data.birthDate!.day}/${data.birthDate!.month}/${data.birthDate!.year}' : 'Select Birth Date',
              style: theme.textTheme.bodyLarge?.copyWith(color: data.birthDate != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.4)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterLinks(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Already have an account?", style: theme.textTheme.bodyMedium),
        TextButton(
          onPressed: () => context.go(AppRouter.helperLogin),
          child: Text("Login", style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
