import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toury/features/tourist/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:toury/features/tourist/features/auth/presentation/cubit/auth_state.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/router/app_router.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go(AppRouter.roleSelection);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: theme.colorScheme.error),
          );
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(loc.translate('account') ?? 'Account'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
          child: Column(
            children: [
              const SizedBox(height: AppTheme.spaceLG),
              // Profile Header
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceXL),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 2),
                          ),
                          child: const CircleAvatar(
                            radius: 45,
                            backgroundColor: AppColor.lightBorder,
                            child: Icon(Icons.person, size: 50, color: AppColor.primaryColor),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.colorScheme.surface, width: 2),
                            ),
                            child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceLG),
                    Text(
                      'Ahmed User',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ahmed@example.com',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space2XL),

              // Settings Groups
              _buildSettingsGroup(
                theme,
                children: [
                  _buildSettingTile(theme, Icons.person_outline_rounded, 'Edit Profile', () {}),
                  _buildSettingTile(theme, Icons.notifications_none_rounded, 'Notifications', () {}),
                  _buildSettingTile(theme, Icons.language_rounded, 'Language', () {}),
                ],
              ),
              const SizedBox(height: AppTheme.spaceLG),
              _buildSettingsGroup(
                theme,
                children: [
                  _buildSettingTile(theme, Icons.security_rounded, 'Security', () {}),
                  _buildSettingTile(theme, Icons.help_outline_rounded, 'Support', () {}),
                  _buildSettingTile(
                    theme,
                    Icons.logout_rounded,
                    'Logout',
                    () => _showLogoutDialog(context),
                    color: theme.colorScheme.error,
                    showTrailing: false,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space2XL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(ThemeData theme, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile(
    ThemeData theme,
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
    bool showTrailing = true,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppTheme.spaceSM),
        decoration: BoxDecoration(
          color: (color ?? theme.colorScheme.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        ),
        child: Icon(icon, color: color ?? theme.colorScheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: showTrailing
          ? Icon(Icons.chevron_right_rounded, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.2))
          : null,
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthCubit>().logout();
            },
            child: Text('Logout', style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
