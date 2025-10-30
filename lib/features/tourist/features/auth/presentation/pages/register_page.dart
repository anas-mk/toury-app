import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/basic_app_bar.dart';
import '../../../../../../core/widgets/custom_text_field.dart';
import '../../../../../../core/localization/app_localizations.dart'; // ✅ الترجمة
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final userNameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final countryController = TextEditingController();

  String selectedGender = 'Male';
  DateTime? selectedBirthDate;

  final List<String> genders = ['Male', 'Female'];

  @override
  void dispose() {
    emailController.dispose();
    userNameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneNumberController.dispose();
    countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!; // ✅ استخدم الترجمة

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0E0E0E)
          : AppColor.primaryColor.withOpacity(0.95),
      appBar: const BasicAppBar(),
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.redAccent,
                ),
              );
            } else if (state is AuthAuthenticated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loc.translate("register_success") ??
                      "Registration successful ✅"),
                ),
              );
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
              );
            }
          },
          builder: (context, state) {
            return Center(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      loc.translate("register") ?? "Register",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.translate("register_subtitle") ??
                          "Create your account to get started",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(20),
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            CustomTextField(
                              hintText: loc.translate("email") ?? "Email",
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.email_outlined,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return loc.translate("field_required") ??
                                      'This field is required';
                                }
                                if (!v.contains('@')) {
                                  return loc.translate("invalid_email") ??
                                      'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              hintText: loc.translate("name") ?? "Username",
                              controller: userNameController,
                              prefixIcon: Icons.person_outline,
                              validator: (v) => v == null || v.isEmpty
                                  ? loc.translate("field_required") ??
                                  'This field is required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              hintText: loc.translate("password") ?? "Password",
                              controller: passwordController,
                              isPassword: true,
                              prefixIcon: Icons.lock_outline,
                              validator: (v) => v == null || v.isEmpty
                                  ? loc.translate("field_required") ??
                                  'This field is required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              hintText: loc.translate("confirm_password") ??
                                  "Confirm Password",
                              controller: confirmPasswordController,
                              isPassword: true,
                              prefixIcon: Icons.lock_outline,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return loc.translate("field_required") ??
                                      'This field is required';
                                }
                                if (v != passwordController.text) {
                                  return loc.translate("passwords_dont_match") ??
                                      'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              hintText: loc.translate("phone_number") ??
                                  "Phone Number",
                              controller: phoneNumberController,
                              keyboardType: TextInputType.phone,
                              prefixIcon: Icons.phone_outlined,
                              validator: (v) => v == null || v.isEmpty
                                  ? loc.translate("field_required") ??
                                  'This field is required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _buildGenderField(isDark, loc),
                            const SizedBox(height: 16),
                            _buildBirthDateField(isDark, loc),
                            const SizedBox(height: 16),
                            CustomTextField(
                              hintText:
                              loc.translate("country") ?? "Country",
                              controller: countryController,
                              prefixIcon: Icons.location_on_outlined,
                              validator: (v) => v == null || v.isEmpty
                                  ? loc.translate("field_required") ??
                                  'This field is required'
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: state is AuthLoading
                                  ? null
                                  : () {
                                if (_formKey.currentState!.validate()) {
                                  if (selectedBirthDate == null) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          loc.translate(
                                              "select_birth_date") ??
                                              'Please select your birth date',
                                        ),
                                        backgroundColor:
                                        Colors.redAccent,
                                      ),
                                    );
                                    return;
                                  }
                                  context.read<AuthCubit>().register(
                                    email: emailController.text.trim(),
                                    userName: userNameController.text
                                        .trim(),
                                    password:
                                    passwordController.text.trim(),
                                    phoneNumber: phoneNumberController
                                        .text
                                        .trim(),
                                    gender: selectedGender,
                                    birthDate: selectedBirthDate!,
                                    country: countryController.text
                                        .trim(),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.primaryColor,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: state is AuthLoading
                                  ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : Text(
                                loc.translate("register_button") ??
                                    'Register',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  loc.translate("already_have_account") ??
                                      "Already have an account?",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const LoginPage(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    loc.translate("login") ?? "Login",
                                    style: const TextStyle(
                                      color: AppColor.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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

  Widget _buildGenderField(bool isDark, AppLocalizations loc) {
    return DropdownButtonFormField<String>(
      value: selectedGender,
      decoration: InputDecoration(
        labelText: loc.translate("gender") ?? 'Gender',
        prefixIcon: Icon(
          Icons.person_2_outlined,
          color: isDark ? Colors.white70 : Colors.grey[700],
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[850] : Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dropdownColor: isDark ? Colors.grey[900] : Colors.white,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      items: [
        DropdownMenuItem(
          value: 'Male',
          child: Text(loc.translate("male") ?? "Male"),
        ),
        DropdownMenuItem(
          value: 'Female',
          child: Text(loc.translate("female") ?? "Female"),
        ),
      ],
      onChanged: (val) => setState(() => selectedGender = val ?? 'Male'),
    );
  }

  Widget _buildBirthDateField(bool isDark, AppLocalizations loc) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedBirthDate ??
              DateTime.now().subtract(const Duration(days: 365 * 18)),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => selectedBirthDate = picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: loc.translate("birth_date") ?? 'Birth Date',
          prefixIcon: Icon(
            Icons.calendar_month_rounded,
            color: isDark ? Colors.white70 : Colors.grey[700],
          ),
          filled: true,
          fillColor: isDark ? Colors.grey[850] : Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          selectedBirthDate != null
              ? '${selectedBirthDate!.day}/${selectedBirthDate!.month}/${selectedBirthDate!.year}'
              : loc.translate("select_birth_date") ??
              'Select your birth date',
          style: TextStyle(
            color: selectedBirthDate != null
                ? (isDark ? Colors.white : Colors.black87)
                : Colors.grey,
          ),
        ),
      ),
    );
  }
}
