import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/pages/profile_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // final t = AppLocalizations.of(context);

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("Toury App"),
          actions: [
            // IconButton(
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (_) => const ProfilePage()),
            //     );
            //   },
            //   icon: const Icon(Icons.person),
            //   tooltip: 'Profile',
            // ),
            IconButton(
              onPressed: () => _showLogoutDialog(context),
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.home, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Welcome to Toury!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your travel companion app',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              // ElevatedButton.icon(
              //   onPressed: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (_) => const ProfilePage()),
              //     );
              //   },
              //   icon: const Icon(Icons.person),
              //   label: const Text('View Profile'),
              //   style: ElevatedButton.styleFrom(
              //     padding: const EdgeInsets.symmetric(
              //       horizontal: 24,
              //       vertical: 12,
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 16),
              // ElevatedButton.icon(
              //   onPressed: () => context.read<ThemeCubit>().toggleTheme(),
              //   icon: const Icon(Icons.brightness_6),
              //   label: const Text("Toggle Theme"),
              //   style: ElevatedButton.styleFrom(
              //     padding: const EdgeInsets.symmetric(
              //       horizontal: 24,
              //       vertical: 12,
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthCubit>().logout();
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
