import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_color.dart';

class HelperHomePage extends StatelessWidget {
  const HelperHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E0E0E) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Helper Home'),
        backgroundColor: isDark ? Colors.grey[900] : AppColor.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Welcome to Helper Home Page!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
