import 'package:flutter/material.dart';

class SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  const SettingTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (iconColor ?? const Color(0xFF6C63FF)).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor ?? const Color(0xFF6C63FF), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            )
          : null,
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white12, size: 14),
    );
  }
}
