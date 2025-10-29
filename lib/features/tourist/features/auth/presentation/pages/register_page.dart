import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/basic_app_bar.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'login_page.dart';
import '../../../../../../core/widgets/custom_text_field.dart';

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

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
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
                const SnackBar(content: Text('Registration successful!')),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Create Account",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Join us and start your journey!",
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
                              hintText: 'Email',
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.email_outlined,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Please enter an email';
                                }
                                if (!v.contains('@')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              hintText: 'Username',
                              controller: userNameController,
                              prefixIcon: Icons.person_outline,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Please enter a username'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              hintText: 'Password',
                              controller: passwordController,
                              isPassword: true,
                              prefixIcon: Icons.lock_outline,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Please enter a password'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              hintText: 'Confirm Password',
                              controller: confirmPasswordController,
                              isPassword: true,
                              prefixIcon: Icons.lock_outline,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (v != passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              hintText: 'Phone Number',
                              controller: phoneNumberController,
                              keyboardType: TextInputType.phone,
                              prefixIcon: Icons.phone_outlined,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Please enter your phone number'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _buildGenderField(isDark),
                            const SizedBox(height: 16),
                            _buildBirthDateField(isDark),
                            const SizedBox(height: 16),
                            CustomTextField(
                              hintText: 'Country',
                              controller: countryController,
                              prefixIcon: Icons.location_on_outlined,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Please enter your country'
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: state is AuthLoading
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        if (selectedBirthDate == null) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Please select your birth date',
                                              ),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                          return;
                                        }
                                        context.read<AuthCubit>().register(
                                          email: emailController.text.trim(),
                                          userName: userNameController.text
                                              .trim(),
                                          password: passwordController.text
                                              .trim(),
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
                                  : const Text(
                                      'Register',
                                      style: TextStyle(
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
                                  "Already have an account?",
                                  style: theme.textTheme.bodyMedium,
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

  Widget _buildGenderField(bool isDark) {
    return DropdownButtonFormField<String>(
      value: selectedGender,
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: Icon(
          Icons.person_2_outlined,
          color: isDark ? Colors.white70 : Colors.grey[700],
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dropdownColor: isDark ? Colors.grey[850] : Colors.white,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      items: genders
          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
          .toList(),
      onChanged: (val) => setState(() => selectedGender = val ?? 'Male'),
    );
  }

  Widget _buildBirthDateField(bool isDark) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate:
              selectedBirthDate ??
              DateTime.now().subtract(const Duration(days: 365 * 18)),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => selectedBirthDate = picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Birth Date',
          prefixIcon: Icon(
            Icons.calendar_month_rounded,
            color: isDark ? Colors.white70 : Colors.grey[700],
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          selectedBirthDate != null
              ? '${selectedBirthDate!.day}/${selectedBirthDate!.month}/${selectedBirthDate!.year}'
              : 'Select your birth date',
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
