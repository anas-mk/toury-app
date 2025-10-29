import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toury/core/theme/app_color.dart';
import 'package:toury/features/tourist/features/auth/presentation/pages/role_selection_page.dart';
import 'package:toury/features/tourist/features/home/presentation/pages/home_layout.dart';
import 'package:toury/features/tourist/features/auth/data/models/user_model.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    await Future.delayed(const Duration(seconds: 3));
    final user = await _getCurrentUser();

    if (!mounted) return;

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeLayout()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
      );
    }
  }

  Future<UserModel?> _getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson == null) return null;
    try {
      final Map<String, dynamic> data = jsonDecode(userJson);
      return UserModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo/logo.png',
              height: 200,
            ),
          ],
        ),
      ),
    );
  }
}
