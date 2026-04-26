import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/animations/fade_in_slide.dart';
import '../../../../../../core/services/haptic_service.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../auth/presentation/cubit/helper_auth_cubit.dart';
import '../../../auth/presentation/cubit/helper_auth_state.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../../domain/entities/helper_profile_entity.dart';
import '../widgets/control_center/setting_tile.dart';
import '../widgets/control_center/setting_section.dart';
import '../widgets/profile_info/profile_info_form.dart';
import 'identity_verification_page.dart';
import 'vehicle_management_page.dart';

class AccountControlCenterPage extends StatefulWidget {
  const AccountControlCenterPage({super.key});

  @override
  State<AccountControlCenterPage> createState() => _AccountControlCenterPageState();
}

class _AccountControlCenterPageState extends State<AccountControlCenterPage> {
  late final ProfileCubit _profileCubit;

  @override
  void initState() {
    super.initState();
    _profileCubit = sl<ProfileCubit>()..fetchProfileBundle();
  }

  @override
  void dispose() {
    _profileCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _profileCubit),
        BlocProvider(create: (context) => sl<HelperAuthCubit>()),
      ],
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          centerTitle: false,
          title: Text(
            'Control Center',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.help_outline_rounded, color: isDark ? Colors.white38 : Colors.black38),
              onPressed: () {},
            ),
          ],
        ),
        body: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state.status == ProfileStatus.loading && state.profile == null) {
              return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
            }
            if (state.profile == null) {
              return _buildErrorState(context);
            }

            final profile = state.profile!;

            return RefreshIndicator(
              onRefresh: () async => _profileCubit.fetchProfileBundle(),
              color: AppColor.primaryColor,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 40),
                children: [
                  FadeInSlide(
                    duration: const Duration(milliseconds: 500),
                    child: _buildHeader(context, profile),
                  ),
                  
                  FadeInSlide(
                    delay: const Duration(milliseconds: 100),
                    child: SettingSection(
                      title: 'Account & Identity',
                      children: [
                        SettingTile(
                          icon: Icons.person_outline_rounded,
                          title: 'Basic Information',
                          subtitle: 'Name, Phone, Birthday',
                          onTap: () {
                            HapticService.light();
                            ProfileInfoForm.show(context, profile);
                          },
                        ),
                        SettingTile(
                          icon: Icons.verified_user_outlined,
                          title: 'Identity Verification',
                          subtitle: 'Documents, Status, Selfie',
                          onTap: () {
                            HapticService.light();
                            Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider.value(value: _profileCubit, child: IdentityVerificationPage(profile: profile))));
                          },
                        ),
                        SettingTile(
                          icon: Icons.directions_car_filled_outlined,
                          title: 'Vehicle Management',
                          subtitle: profile.car != null ? '${profile.car!.brand} ${profile.car!.model}' : 'No vehicle added',
                          onTap: () {
                            HapticService.light();
                            Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleManagementPage(car: profile.car)));
                          },
                        ),
                        SettingTile(
                          icon: Icons.card_membership_rounded,
                          title: 'Certificates & Languages',
                          subtitle: '${profile.certificates.length} certificates',
                          onTap: () => HapticService.light(),
                        ),
                      ],
                    ),
                  ),

                  FadeInSlide(
                    delay: const Duration(milliseconds: 200),
                    child: SettingSection(
                      title: 'Preferences',
                      children: [
                        SettingTile(
                          icon: Icons.language_rounded,
                          title: 'App Language',
                          subtitle: 'English (US)',
                          onTap: () => HapticService.light(),
                        ),
                        SettingTile(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notifications',
                          subtitle: 'Push, Email, SMS',
                          onTap: () => HapticService.light(),
                        ),
                        SettingTile(
                          icon: Icons.dark_mode_outlined,
                          title: 'Theme & Appearance',
                          subtitle: 'Dark Mode',
                          onTap: () => HapticService.light(),
                        ),
                      ],
                    ),
                  ),

                  FadeInSlide(
                    delay: const Duration(milliseconds: 300),
                    child: SettingSection(
                      title: 'Security',
                      children: [
                        SettingTile(
                          icon: Icons.lock_outline_rounded,
                          title: 'Change Password',
                          onTap: () => HapticService.light(),
                        ),
                        SettingTile(
                          icon: Icons.fingerprint_rounded,
                          title: 'Biometric Login',
                          trailing: Switch(
                            value: true, 
                            onChanged: (v) {
                              HapticService.medium();
                            }, 
                            activeColor: theme.colorScheme.primary,
                          ),
                          onTap: () => HapticService.light(),
                        ),
                      ],
                    ),
                  ),

                  FadeInSlide(
                    delay: const Duration(milliseconds: 400),
                    child: SettingSection(
                      title: 'Support',
                      children: [
                        SettingTile(
                          icon: Icons.help_center_outlined,
                          title: 'Help Center',
                          onTap: () => HapticService.light(),
                        ),
                        SettingTile(
                          icon: Icons.report_problem_outlined,
                          title: 'Resolution Center',
                          subtitle: 'View your reports & resolutions',
                          onTap: () {
                            HapticService.light();
                            context.push('/helper/reports');
                          },
                        ),
                        SettingTile(
                          icon: Icons.policy_outlined,
                          title: 'Terms & Privacy',
                          onTap: () => HapticService.light(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FadeInSlide(
                      delay: const Duration(milliseconds: 500),
                      child: BlocListener<HelperAuthCubit, HelperAuthState>(
                        listener: (context, authState) {
                          if (authState is HelperAuthUnauthenticated) {
                            context.go('/role-selection');
                          }
                        },
                        child: _LogoutButton(onTap: () {
                          HapticService.medium();
                          _showLogoutConfirm(context);
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'App Version 2.4.0 (Build 124)',
                      style: TextStyle(color: isDark ? Colors.white12 : Colors.black12, fontSize: 11),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, HelperProfileEntity profile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                backgroundImage: profile.profileImageUrl != null ? NetworkImage(profile.profileImageUrl!) : null,
                child: profile.profileImageUrl == null
                    ? Icon(Icons.person_rounded, color: theme.colorScheme.primary, size: 40)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppColor.accentColor, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  style: TextStyle(color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    'PRO HELPER',
                    style: TextStyle(color: theme.colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColor.errorColor, size: 48),
          const SizedBox(height: 16),
          Text('Failed to load profile', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () => _profileCubit.fetchProfileBundle(), child: const Text('Retry')),
        ],
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.dialogBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: AppColor.errorColor.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.logout_rounded, color: AppColor.errorColor, size: 28),
              ),
              const SizedBox(height: 20),
              Text('Are you sure?', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                'You will need to login again to access your dashboard.',
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<HelperAuthCubit>().logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.errorColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColor.errorColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.errorColor.withOpacity(0.3)),
        ),
        child: const Center(
          child: Text(
            'Logout',
            style: TextStyle(color: AppColor.errorColor, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
