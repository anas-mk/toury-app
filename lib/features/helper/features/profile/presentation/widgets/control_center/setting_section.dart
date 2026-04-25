import 'package:flutter/material.dart';

class SettingSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingSection({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white24,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F3C),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
