import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/localization/app_localizations.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('account')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppColor.lightBorder,
              child: Icon(Icons.person, size: 50, color: AppColor.primaryColor),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            Text('Ahmed User', style: theme.textTheme.headlineSmall),
            const Text('ahmed@example.com', style: TextStyle(color: AppColor.lightTextSecondary)),
            const SizedBox(height: AppTheme.space2XL),
            
            _buildSettingTile(Icons.person_outline_rounded, 'Edit Profile', () {}),
            _buildSettingTile(Icons.notifications_none_rounded, 'Notifications', () {}),
            _buildSettingTile(Icons.language_rounded, 'Language', () {}),
            _buildSettingTile(Icons.security_rounded, 'Security', () {}),
            _buildSettingTile(Icons.help_outline_rounded, 'Support', () {}),
            const Divider(height: AppTheme.space2XL),
            _buildSettingTile(Icons.logout_rounded, 'Logout', () {}, color: AppColor.errorColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColor.primaryColor),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
      onTap: onTap,
    );
  }
}
