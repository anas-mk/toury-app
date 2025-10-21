import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toury/core/presentation/widgets/basic_app_bar.dart';
import '../../../../core/theme/app_color.dart';
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
  final TextEditingController emailController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController countryController = TextEditingController();

  String selectedGender = 'Male';
  DateTime? selectedBirthDate;
  bool isObscured = true;
  bool isConfirmObscured = true;

  final List<String> genders = ['Male', 'Female', 'Other'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      appBar: BasicAppBar(),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header
                    const Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Join us and start your journey!",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Card Form
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
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
                            // Email
                            TextFormField(
                              controller: emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Please enter an email';
                                if (!v.contains('@')) return 'Enter a valid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Username
                            TextFormField(
                              controller: userNameController,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Please enter a username'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // Password
                            TextFormField(
                              controller: passwordController,
                              obscureText: isObscured,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    transitionBuilder:
                                        (Widget child, Animation<double> animation) =>
                                        ScaleTransition(scale: animation, child: child),
                                    child: Icon(
                                      isObscured
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      key: ValueKey<bool>(isObscured),
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() => isObscured = !isObscured);
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Enter a password';
                                if (v.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password
                            TextFormField(
                              controller: confirmPasswordController,
                              obscureText: isConfirmObscured,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    transitionBuilder:
                                        (Widget child, Animation<double> animation) =>
                                        ScaleTransition(scale: animation, child: child),
                                    child: Icon(
                                      isConfirmObscured
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      key: ValueKey<bool>(isConfirmObscured),
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() =>
                                    isConfirmObscured = !isConfirmObscured);
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
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

                            // Phone Number
                            TextFormField(
                              controller: phoneNumberController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                prefixIcon: const Icon(Icons.phone_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Please enter your phone number'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // Gender
                            DropdownButtonFormField<String>(
                              value: selectedGender,
                              decoration: InputDecoration(
                                labelText: 'Gender',
                                prefixIcon: const Icon(Icons.person_2_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              items: genders.map((gender) {
                                return DropdownMenuItem(
                                  value: gender,
                                  child: Text(gender),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => selectedGender = val);
                              },
                            ),
                            const SizedBox(height: 16),

                            // Birth Date
                            InkWell(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedBirthDate ??
                                      DateTime.now().subtract(
                                        const Duration(days: 365 * 18),
                                      ),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() => selectedBirthDate = picked);
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Birth Date',
                                  prefixIcon: const Icon(Icons.calendar_month_rounded),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  selectedBirthDate != null
                                      ? '${selectedBirthDate!.day}/${selectedBirthDate!.month}/${selectedBirthDate!.year}'
                                      : 'Select your birth date',
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Country
                            TextFormField(
                              controller: countryController,
                              decoration: InputDecoration(
                                labelText: 'Country',
                                prefixIcon: const Icon(Icons.location_on_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Please enter your country'
                                  : null,
                            ),
                            const SizedBox(height: 24),

                            // Register Button
                            ElevatedButton(
                              onPressed: state is AuthLoading
                                  ? null
                                  : () {
                                if (_formKey.currentState!.validate()) {
                                  if (selectedBirthDate == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Please select your birth date'),
                                      ),
                                    );
                                    return;
                                  }
                                  context.read<AuthCubit>().register(
                                    email: emailController.text.trim(),
                                    userName:
                                    userNameController.text.trim(),
                                    password: passwordController.text,
                                    phoneNumber:
                                    phoneNumberController.text.trim(),
                                    gender: selectedGender,
                                    birthDate: selectedBirthDate!,
                                    country:
                                    countryController.text.trim(),
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
                                const Text(
                                  "Already have an account?",
                                  style: TextStyle(fontSize: 15,),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const LoginPage()),
                                    );
                                  },
                                  child: const Text(
                                    "Login",
                                    style: TextStyle(
                                      color: AppColor.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              ],
                            )
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
}
