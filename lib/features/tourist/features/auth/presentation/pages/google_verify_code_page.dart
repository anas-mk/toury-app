import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../home/presentation/pages/home_layout.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class GoogleVerifyCodePage extends StatefulWidget {
  final String email;
  const GoogleVerifyCodePage({super.key, required this.email});

  @override
  State<GoogleVerifyCodePage> createState() => _GoogleVerifyCodePageState();
}

class _GoogleVerifyCodePageState extends State<GoogleVerifyCodePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Code'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is AuthAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration successful!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeLayout()),
              (route) => false,
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const Icon(Icons.verified_user, size: 80, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text(
                    'Verify Your Email',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a verification code to ${widget.email}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Verification Code
                  TextFormField(
                    controller: codeController,
                    enabled: state is! AuthLoading,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Verification Code',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.security),
                      hintText: 'Enter 6-digit code',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter the verification code';
                      }
                      if (value.trim().length != 6) {
                        return 'Please enter a valid 6-digit code';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Verify Button
                  ElevatedButton(
                    onPressed: state is AuthLoading
                        ? null
                        : () {
                            // if (_formKey.currentState!.validate()) {
                            //   context.read<AuthCubit>().verifyGoogleCode(
                            //     email: widget.email,
                            //     code: codeController.text.trim(),
                            //   );
                            // }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
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
                            'Verify Code',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Resend Code Button
                  TextButton(
                    onPressed: state is AuthLoading
                        ? null
                        : () {
                            // TODO: Implement resend code functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Resend code functionality not implemented yet',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                    child: const Text(
                      'Resend Code',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

