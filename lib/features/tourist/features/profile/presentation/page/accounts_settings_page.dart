import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/localization/cubit/localization_cubit.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/theme/theme_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../widgets/profile_box.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = context.watch<ThemeCubit>().state == ThemeMode.dark;

    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthUnauthenticated) {
              context.go(AppRouter.roleSelection);
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.translate('account') ?? 'Account'),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: ProfileBox(isDark: isDark),
              ),
              const SizedBox(height: 16),
              
              // Top Action Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildActionBox(
                        icon: Icons.help_center,
                        title: loc.translate('help') ?? 'Help',
                        onTap: () {},
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionBox(
                        icon: Icons.account_balance_wallet,
                        title: loc.translate('wallet') ?? 'Wallet',
                        onTap: () {},
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionBox(
                        icon: Icons.history,
                        title: loc.translate('activity') ?? 'Activity',
                        onTap: () {},
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              Divider(thickness: 8, color: isDark ? Colors.grey[900] : Colors.grey[100]),
              
              // Settings List
              _buildListTile(
                icon: Icons.settings,
                title: loc.translate('settings') ?? 'Settings',
                onTap: () {},
                isDark: isDark,
              ),
              _buildListTile(
                icon: Icons.support_agent,
                title: loc.translate('contact_us') ?? 'Contact Us',
                onTap: () {},
                isDark: isDark,
              ),
              _buildListTile(
                icon: Icons.dark_mode,
                title: isDark ? (loc.translate('light_mode') ?? 'Light Mode') : (loc.translate('dark_mode') ?? 'Dark Mode'),
                onTap: () => context.read<ThemeCubit>().toggleTheme(),
                isDark: isDark,
              ),
              _buildListTile(
                icon: Icons.language,
                title: loc.translate('toggle_language') ?? 'Change Language',
                onTap: () => context.read<LocalizationCubit>().toggleLanguage(),
                isDark: isDark,
              ),

              Divider(thickness: 8, color: isDark ? Colors.grey[900] : Colors.grey[100]),

              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, authState) {
                  final isLoading = authState is AuthLoading;
                  return InkWell(
                    onTap: isLoading ? null : () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text(loc.translate('logout') ?? 'Logout'),
                          content: Text(loc.translate('logout_confirmation') ?? 'Are you sure you want to logout?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(loc.translate('cancel') ?? 'Cancel')),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                context.read<AuthCubit>().logout();
                              },
                              child: Text(loc.translate('logout') ?? 'Logout', style: const TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red, size: 24),
                          const SizedBox(width: 16),
                          Text(
                            loc.translate('logout') ?? 'Logout',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.red),
                          ),
                          const Spacer(),
                          if (isLoading)
                            const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red)),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBox({required IconData icon, required String title, required VoidCallback onTap, required bool isDark}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: isDark ? Colors.white : Colors.black),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({required IconData icon, required String title, required VoidCallback onTap, required bool isDark}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: isDark ? Colors.white : Colors.black),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
