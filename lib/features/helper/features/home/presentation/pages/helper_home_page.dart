import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../auth/presentation/cubit/helper_auth_cubit.dart';
import '../../../auth/presentation/cubit/helper_auth_state.dart';

class HelperHomePage extends StatelessWidget {
  const HelperHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<HelperAuthCubit, HelperAuthState>(
      listener: (context, state) {
        if (state is HelperAuthUnauthenticated) {
          context.go(AppRouter.roleSelection);
        } else if (state is HelperAuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0E0E0E) : Colors.grey[50],
          appBar: AppBar(
            title: const Text('Helper Home'),
            backgroundColor: isDark ? Colors.grey[900] : AppColor.primaryColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: () => _showLogoutDialog(context),
              ),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state is HelperAuthLoading)
                  const CircularProgressIndicator()
                else ...[
                  const Icon(Icons.dashboard_customize_outlined, size: 64, color: AppColor.primaryColor),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome to Helper Home!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your professional dashboard',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      context.read<HelperAuthCubit>().logout();
    }
  }
}
