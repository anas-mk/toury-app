import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/localization/cubit/localization_cubit.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/theme/app_color.dart';
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
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : AppColor.primaryColor,
        appBar: AppBar(
          backgroundColor: isDark ? Colors.black : AppColor.primaryColor,
          elevation: 0,
          title: Text(
            loc.translate('settings'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? Colors.black : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Profile Box
                ProfileBox(isDark: isDark),

                const SizedBox(height: 25),

                _animatedSection(
                  child: GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildCard(
                        icon: Icons.favorite_border,
                        title: loc.translate('favorites'),
                        color: Colors.pinkAccent,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                loc.translate('feature_coming_soon') ??
                                    'Feature coming soon!',
                              ),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                      _buildCard(
                        icon: Icons.history,
                        title: loc.translate('history'),
                        color: Colors.blueAccent,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                loc.translate('feature_coming_soon') ??
                                    'Feature coming soon!',
                              ),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                      _buildCard(
                        icon: Icons.account_balance_wallet,
                        title: loc.translate('wallet'),
                        color: Colors.green,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                loc.translate('feature_coming_soon') ??
                                    'Feature coming soon!',
                              ),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                _buildSectionTitle(loc.translate('account'), isDark),
                _buildFullWidthButton(
                  icon: Icons.settings,
                  title: loc.translate('settings'),
                  color: Colors.blueGrey,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          loc.translate('feature_coming_soon') ??
                              'Feature coming soon!',
                        ),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildFullWidthButton(
                  icon: Icons.support_agent,
                  title: loc.translate('contact_us'),
                  color: Colors.teal,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          loc.translate('feature_coming_soon') ??
                              'Feature coming soon!',
                        ),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildSectionTitle(loc.translate('preferences'), isDark),
                _buildFullWidthButton(
                  icon: Icons.dark_mode,
                  title: isDark
                      ? (loc.translate('light_mode'))
                      : (loc.translate('dark_mode')),
                  color: Colors.indigo,
                  onTap: () => context.read<ThemeCubit>().toggleTheme(),
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildFullWidthButton(
                  icon: Icons.language,
                  title: loc.translate('toggle_language'),
                  color: Colors.deepPurple,
                  onTap: () {
                    context.read<LocalizationCubit>().toggleLanguage();
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                _buildSectionTitle(loc.translate('account_actions'), isDark),

                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, authState) {
                    final isLoading = authState is AuthLoading;

                    return _buildFullWidthButton(
                      icon: isLoading ? Icons.hourglass_empty : Icons.logout,
                      title: loc.translate('logout'),
                      color: Colors.redAccent,
                      onTap: isLoading
                          ? () {}
                          : () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: Text(loc.translate('logout') ?? 'Logout'),
                            content: Text(
                              loc.translate('logout_confirmation') ??
                                  'Are you sure you want to logout?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: Text(loc.translate('cancel') ?? 'Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                  context.read<AuthCubit>().logout();
                                },
                                child: Text(
                                  loc.translate('logout') ?? 'Logout',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      isDark: isDark,
                      isLoading: isLoading,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper for animations
  static Widget _animatedSection({required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 20),
          child: child,
        ),
      ),
    );
  }

  static Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white70 : Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static Widget _buildCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 34, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildFullWidthButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
    bool isLoading = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            isLoading
                ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.redAccent,
              ),
            )
                : Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: isDark ? Colors.white70 : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}