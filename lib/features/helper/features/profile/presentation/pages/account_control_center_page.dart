import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/animations/fade_in_slide.dart';
import '../../../../../../core/services/haptic_service.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../auth/presentation/cubit/helper_auth_cubit.dart';
import '../../../auth/presentation/cubit/helper_auth_state.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../../domain/entities/helper_profile_entity.dart';
import '../widgets/profile_setting_widgets.dart';
import 'helper_profile_view_page.dart';

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
    final palette = AppColors.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _profileCubit),
        BlocProvider(create: (context) => sl<HelperAuthCubit>()),
      ],
      child: Scaffold(
        backgroundColor: palette.scaffold,
        body: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state.status == ProfileStatus.loading && state.profile == null) {
              return Center(child: CircularProgressIndicator(color: palette.primary));
            }
            if (state.profile == null) {
              return _ErrorState(onRetry: _profileCubit.fetchProfileBundle);
            }

            final profile = state.profile!;

            return RefreshIndicator(
              onRefresh: () async => _profileCubit.fetchProfileBundle(),
              color: palette.primary,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  _ModernAppBar(
                    profile: profile,
                    onHeroTap: () {
                      HapticService.light();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: _profileCubit,
                            child: const HelperProfileViewPage(),
                          ),
                        ),
                      );
                    },
                  ),

                  const SliverToBoxAdapter(
                    child: FadeInSlide(
                      duration: Duration(milliseconds: 500),
                      child: _StatStrip(),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: FadeInSlide(
                      delay: const Duration(milliseconds: 160),
                      child: ProfileSettingGroup(
                        title: 'Preferences',
                        items: [
                          ProfileSettingItem(
                            icon: Icons.language_rounded,
                            iconColor: const Color(0xFF00B8A9),
                            title: 'App Language',
                            subtitle: 'English (US)',
                            onTap: () => HapticService.light(),
                          ),
                          ProfileSettingItem(
                            icon: Icons.notifications_none_rounded,
                            iconColor: const Color(0xFFFF6B9D),
                            title: 'Notifications',
                            subtitle: 'Push, email, SMS',
                            onTap: () => HapticService.light(),
                          ),
                          ProfileSettingItem(
                            icon: Icons.dark_mode_outlined,
                            iconColor: const Color(0xFF6C7BFF),
                            title: 'Theme & Appearance',
                            subtitle: palette.isDark ? 'Dark mode' : 'Light mode',
                            onTap: () => HapticService.light(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: FadeInSlide(
                      delay: const Duration(milliseconds: 240),
                      child: ProfileSettingGroup(
                        title: 'Security',
                        items: [
                          ProfileSettingItem(
                            icon: Icons.lock_outline_rounded,
                            iconColor: palette.danger,
                            title: 'Change Password',
                            subtitle: 'Update your password',
                            onTap: () => HapticService.light(),
                          ),
                          ProfileSettingItem(
                            icon: Icons.fingerprint_rounded,
                            iconColor: palette.primary,
                            title: 'Biometric Login',
                            subtitle: 'Face ID / Fingerprint',
                            trailing: Switch(
                              value: true,
                              onChanged: (v) => HapticService.medium(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: FadeInSlide(
                      delay: const Duration(milliseconds: 320),
                      child: ProfileSettingGroup(
                        title: 'Support',
                        items: [
                          ProfileSettingItem(
                            icon: Icons.help_center_outlined,
                            iconColor: palette.primary,
                            title: 'Help Center',
                            subtitle: 'FAQ & guides',
                            onTap: () => HapticService.light(),
                          ),
                          ProfileSettingItem(
                            icon: Icons.report_problem_outlined,
                            iconColor: const Color(0xFFFFB020),
                            title: 'Resolution Center',
                            subtitle: 'View your reports & resolutions',
                            onTap: () {
                              HapticService.light();
                              context.push('/helper/reports');
                            },
                          ),
                          ProfileSettingItem(
                            icon: Icons.policy_outlined,
                            iconColor: palette.textSecondary,
                            title: 'Terms & Privacy',
                            subtitle: 'Legal information',
                            onTap: () => HapticService.light(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: FadeInSlide(
                      delay: const Duration(milliseconds: 400),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                        child: BlocListener<HelperAuthCubit, HelperAuthState>(
                          listener: (context, authState) {
                            if (authState is HelperAuthUnauthenticated) {
                              context.go('/role-selection');
                            }
                          },
                          child: _LogoutButton(
                            onTap: () {
                              HapticService.medium();
                              _showLogoutConfirm(context);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Toury · v2.4.0 (Build 124)',
                          style: TextStyle(
                            color: palette.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
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

  void _showLogoutConfirm(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: palette.surfaceElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      palette.danger.withValues(alpha: 0.18),
                      palette.danger.withValues(alpha: 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.logout_rounded, color: palette.danger, size: 30),
              ),
              const SizedBox(height: 20),
              Text(
                'Sign out of Toury?',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'You will need to log in again to access your dashboard and active jobs.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<HelperAuthCubit>().logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.danger,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
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

// ──────────────────────────────────────────────────────────────────────────────
//  HERO APP BAR
// ──────────────────────────────────────────────────────────────────────────────

class _ModernAppBar extends StatelessWidget {
  final HelperProfileEntity profile;
  final VoidCallback? onHeroTap;
  const _ModernAppBar({required this.profile, this.onHeroTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final isDark = palette.isDark;

    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      stretch: true,
      automaticallyImplyLeading: false,
      backgroundColor: palette.scaffold,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'Control Center',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: palette.textPrimary,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Padding(
          padding: const EdgeInsets.only(top: 56),
          child: _HeroHeader(
            profile: profile,
            isDark: isDark,
            onTap: onHeroTap,
          ),
        ),
      ),
    );
  }
}

// ─── HERO HEADER ──────────────────────────────────────────────────────────────
//
// Clean horizontal "list-tile" card:
//   - Soft surface card with subtle shadow
//   - Circle avatar on the left
//   - Display name (bold) + email (muted) stacked in the middle
//   - Chevron on the right indicating navigation
//
class _HeroHeader extends StatelessWidget {
  final HelperProfileEntity profile;
  final bool isDark;
  final VoidCallback? onTap;
  const _HeroHeader({
    required this.profile,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Material(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.border, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDark ? 0.30 : 0.06,
                  ),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              child: Row(
                children: [
                  _Avatar(profile: profile),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          profile.fullName.isNotEmpty
                              ? profile.fullName
                              : 'Helper',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            letterSpacing: 0.1,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _VerifiedStatus(isApproved: profile.isApproved),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: palette.textMuted,
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final HelperProfileEntity profile;
  const _Avatar({required this.profile});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final hasImage = profile.profileImageUrl != null &&
        profile.profileImageUrl!.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.primary.withValues(alpha: 0.10),
          ),
          child: ClipOval(
            child: hasImage
                ? Image.network(
                    profile.profileImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.person_rounded,
                      color: palette.primary,
                      size: 32,
                    ),
                  )
                : Icon(
                    Icons.person_rounded,
                    color: palette.primary,
                    size: 32,
                  ),
          ),
        ),
        if (profile.isApproved)
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(color: palette.surface, width: 2),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 10,
              ),
            ),
          ),
      ],
    );
  }
}

class _VerifiedStatus extends StatelessWidget {
  final bool isApproved;
  const _VerifiedStatus({required this.isApproved});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final color = isApproved ? const Color(0xFF22C55E) : palette.warning;
    final label = isApproved ? 'Verified Helper' : 'Pending review';
    final icon = isApproved
        ? Icons.verified_rounded
        : Icons.hourglass_top_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: palette.isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: color.withValues(alpha: 0.30),
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  QUICK SHORTCUTS STRIP
// ──────────────────────────────────────────────────────────────────────────────

class _StatStrip extends StatelessWidget {
  const _StatStrip();

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              icon: Icons.travel_explore_rounded,
              label: 'Coverage',
              value: 'Regions',
              color: const Color(0xFFFFB020),
              onTap: () {
                HapticService.light();
                context.push('/helper/service-areas');
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
              icon: Icons.receipt_long_outlined,
              label: 'Receipts',
              value: 'Invoices',
              color: palette.primary,
              onTap: () {
                HapticService.light();
                context.pushNamed('helper-invoices');
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Earnings',
              value: 'Wallet',
              color: palette.success,
              onTap: () {
                HapticService.light();
                context.goNamed('helper-wallet');
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(
                        alpha: palette.isDark ? 0.18 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 16),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_outward_rounded,
                    color: palette.textMuted,
                    size: 14,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: palette.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Section group + setting item widgets now live in
// ../widgets/profile_setting_widgets.dart (reused by helper_profile_view_page).

// ──────────────────────────────────────────────────────────────────────────────
//  LOGOUT BUTTON
// ──────────────────────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: palette.danger.withValues(alpha: palette.isDark ? 0.14 : 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: palette.danger.withValues(alpha: 0.22),
              width: 1,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.logout_rounded, color: palette.danger, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Sign Out',
                  style: TextStyle(
                    color: palette.danger,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  ERROR STATE
// ──────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: palette.danger.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_off_rounded, color: palette.danger, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'Couldn\'t load your profile',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
