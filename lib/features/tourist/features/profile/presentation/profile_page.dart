import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toury/features/tourist/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:toury/features/tourist/features/auth/presentation/cubit/auth_state.dart';
import 'package:toury/features/tourist/features/auth/presentation/pages/login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            // Navigate to login page after logout
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // User Info
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: state.user.profileImageUrl != null &&
                            state.user.profileImageUrl!.isNotEmpty
                            ? NetworkImage(state.user.profileImageUrl!)
                            : null,
                        child: state.user.profileImageUrl == null ||
                            state.user.profileImageUrl!.isEmpty
                            ? const Icon(Icons.person,
                            size: 50, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.user.userName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.user.email,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // User Details Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildInfoRow(
                                icon: Icons.phone,
                                label: 'Phone Number',
                                value: state.user.phoneNumber ?? 'Not provided',
                              ),
                              const Divider(height: 24),
                              _buildInfoRow(
                                icon: Icons.male,
                                label: 'Gender',
                                value: state.user.gender ?? 'Not specified',
                              ),
                              const Divider(height: 24),
                              _buildInfoRow(
                                icon: Icons.cake,
                                label: 'Birth Date',
                                value: state.user.birthDate.toString().split(' ')[0] ?? 'Not provided',
                              ),
                              const Divider(height: 24),
                              _buildInfoRow(
                                icon: Icons.location_on,
                                label: 'Country',
                                value: state.user.country ?? 'Not specified',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Profile Options
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Edit Profile'),
                        trailing:
                        const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Navigate to edit profile
                        },
                      ),


                    ],
                  ),
                ),
              );
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }
}