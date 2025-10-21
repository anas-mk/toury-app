import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/presentation/widgets/basic_app_bar.dart';
import '../../../../core/theme/app_color.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'enter_password_page.dart';
import 'register_page.dart';
import 'google_register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();

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
            } else if (state is AuthEmailExists) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EnterPasswordPage(email: state.email),
                ),
              );
            } else if (state is AuthGoogleRegistrationNeeded) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      GoogleRegisterPage(googleToken: state.googleToken),
                ),
              );
            }
          },
          builder: (context, state) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo or Icon
                    Image.asset(
                      'assets/logo/logo.png',
                      height: 200,
                    ),
                    // Card Container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Email Field
                          TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            enabled: state is! AuthLoading,
                          ),
                          const SizedBox(height: 20),

                          // Login Button
                          ElevatedButton(
                            onPressed: state is AuthLoading
                                ? null
                                : () {
                                    final email = emailController.text.trim();
                                    if (email.isEmpty ||
                                        !email.contains('@')) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please enter a valid email',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    context.read<AuthCubit>().checkEmail(
                                      email,
                                    );
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
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),

                          // Divider
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Google Sign-In Button
                          OutlinedButton.icon(
                            onPressed: state is AuthLoading
                                ? null
                                : () => _handleGoogleSignIn(context),
                            icon: const Icon(
                                Icons.g_mobiledata,
                                size: 24,
                                color: AppColor.primaryColor,
                            ),
                            label: const Text(
                                'Continue with Google',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColor.primaryColor,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              side: const BorderSide(color: AppColor.primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),

                          // Register
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account?",
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const RegisterPage()),
                                  );
                                },
                                child: const Text(
                                  "Register",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,

                                  ),
                                ),
                              )
                            ],
                          )

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

  void _handleGoogleSignIn(BuildContext context) {
    // For now, we'll simulate a Google token
    // In a real app, you would integrate with google_sign_in package
    const String mockGoogleToken = "mock_google_token_12345";

    context.read<AuthCubit>().googleLogin(mockGoogleToken);
  }
}
