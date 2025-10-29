import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toury/features/tourist/features/auth/presentation/pages/role_selection_page.dart';
import 'package:toury/features/tourist/features/profile/presentation/profile_page.dart';
import '../../../../../../core/router/app_navigator.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/theme_cubit.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../../../profile/cubit/profile_cubit/profile_cubit.dart';
import '../../../profile/cubit/profile_cubit/profile_state.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit()..loadUser(),
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final isDark = context.watch<ThemeCubit>().state == ThemeMode.dark;

          return Scaffold(
            backgroundColor: isDark ? Colors.black : AppColor.primaryColor,
            appBar: AppBar(
              backgroundColor: isDark ? Colors.black : AppColor.primaryColor,
              elevation: 0,
              title: const Text(
                "Account Settings",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
            body: switch (state) {
              ProfileLoading() =>
              const Center(child: CircularProgressIndicator()),
              ProfileError(:final message) => Center(
                  child: Text(message,
                      style: const TextStyle(color: Colors.red))),
              ProfileLoaded(:final user) => Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.black : Colors.white,
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // --- Profile Box ---
                      InkWell(
                        onTap: () {
                          AppNavigator.push(context, const ProfilePage());
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
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
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 35,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: user.profileImageUrl != null
                                    ? NetworkImage(user.profileImageUrl!)
                                    : null,
                                child: user.profileImageUrl == null
                                    ? Text(
                                  user.userName[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.userName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user.email,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 18,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // --- Quick Actions ---
                      GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildCard(
                            icon: Icons.favorite_border,
                            title: "Favorites",
                            color: Colors.pinkAccent,
                            onTap: () {},
                            isDark: isDark,
                          ),
                          _buildCard(
                            icon: Icons.history,
                            title: "History",
                            color: Colors.blueAccent,
                            onTap: () {},
                            isDark: isDark,
                          ),
                          _buildCard(
                            icon: Icons.account_balance_wallet,
                            title: "Wallet",
                            color: Colors.green,
                            onTap: () {},
                            isDark: isDark,
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // --- Account Section ---
                      _buildSectionTitle("Account", isDark),
                      _buildFullWidthButton(
                        icon: Icons.settings,
                        title: "Settings",
                        color: Colors.blueGrey,
                        onTap: () {},
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      _buildFullWidthButton(
                        icon: Icons.support_agent,
                        title: "Contact Us",
                        color: Colors.teal,
                        onTap: () {},
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      // --- Preferences Section ---
                      _buildSectionTitle("Preferences", isDark),
                      _buildFullWidthButton(
                        icon: Icons.dark_mode,
                        title: isDark ? "Light Mode" : "Dark Mode",
                        color: Colors.indigo,
                        onTap: () => context.read<ThemeCubit>().toggleTheme(),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      _buildFullWidthButton(
                        icon: Icons.language,
                        title: "Change Language",
                        color: Colors.deepPurple,
                        onTap: () {},
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      // --- Account Actions Section ---
                      _buildSectionTitle("Account Actions", isDark),
                      _buildFullWidthButton(
                        icon: Icons.logout,
                        title: "Logout",
                        color: Colors.redAccent,
                        onTap: () async {
                          await AuthLocalDataSourceImpl().clearUser();
                          AppNavigator.pushAndRemove(
                            context, const RoleSelectionPage(),
                          );
                        },

                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),
              _ => const SizedBox.shrink(),
            },
          );
        },
      ),
    );
  }

  // --- Helper Widgets ---
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
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
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
            Icon(
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
