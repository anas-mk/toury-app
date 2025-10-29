import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toury/core/theme/app_color.dart';
import 'package:toury/core/theme/theme_cubit.dart';
import '../cubit/profile_cubit/profile_cubit.dart';
import '../cubit/profile_cubit/profile_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit()..loadUser(),
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final isDark = context.watch<ThemeCubit>().state == ThemeMode.dark;

          return Scaffold(
            backgroundColor: isDark
                ? const Color(0xFF0E0E0E)
                : const Color(0xFFF9FAFB),
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: switch (state) {
                ProfileLoading() => const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.blueAccent,
                  ),
                ),
                ProfileError(:final message) => Center(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                ProfileLoaded(:final user) => CustomScrollView(
                  slivers: [
                    // ---- Header ----
                    SliverAppBar(
                      expandedHeight: 310,
                      pinned: true,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColor.primaryColor,
                                    AppColor.primaryColor.withOpacity(0.7),
                                    isDark
                                        ? Colors.black
                                        : Colors.lightBlueAccent.withOpacity(
                                            0.4,
                                          ),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 10,
                                  sigmaY: 10,
                                ),
                                child: Container(
                                  color: Colors.black.withOpacity(0.1),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 25,
                                  top: 40,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 60,
                                      backgroundColor: Colors.white,
                                      backgroundImage:
                                          user.profileImageUrl != null
                                          ? NetworkImage(user.profileImageUrl!)
                                          : null,
                                      child: user.profileImageUrl == null
                                          ? Text(
                                              user.userName[0].toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 42,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black54,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      user.userName,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.white,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),

                    // ---- User information ----
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildInfoTile(
                              icon: Icons.email_rounded,
                              label: "Email",
                              value: user.email,
                              isDark: isDark,
                            ),
                            _buildInfoTile(
                              icon: Icons.phone_rounded,
                              label: "Phone",
                              value: user.phoneNumber,
                              isDark: isDark,
                            ),
                            _buildInfoTile(
                              icon: Icons.wc_rounded,
                              label: "Gender",
                              value: user.gender,
                              isDark: isDark,
                            ),
                            _buildInfoTile(
                              icon: Icons.flag_circle_outlined,
                              label: "Country",
                              value: user.country,
                              isDark: isDark,
                            ),
                            _buildInfoTile(
                              icon: Icons.cake_rounded,
                              label: "Birth Date",
                              value: user.birthDate.toString().split(' ')[0],
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                _ => const SizedBox.shrink(),
              },
            ),
          );
        },
      ),
    );
  }

  static Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColor.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: AppColor.primaryColor, size: 24),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
