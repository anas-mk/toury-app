import 'package:flutter/material.dart';
import '../../../../core/theme/app_color.dart';
import 'login_page.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B3D91),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Image.asset(
                  'assets/logo/logo.png',
                  height: 200,
                ),
                const SizedBox(height: 30),

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
                    children: [
                      const Text(
                        "Continue as",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColor.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Tourist Button
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                              // settings: const RouteSettings(arguments: 'tourist'),
                            ),
                          );
                        },
                        label: const Text(
                          'Tourist',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primaryColor,
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Guide Button
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                              // settings: const RouteSettings(arguments: 'guide'),
                            ),
                          );
                        },
                        label: const Text(
                          'Guide',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColor.primaryColor,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 55),
                          side: const BorderSide(color: AppColor.primaryColor, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Footer
                Text(
                  'Select your role to continue',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
