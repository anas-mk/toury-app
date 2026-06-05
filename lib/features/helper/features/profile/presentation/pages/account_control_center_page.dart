import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/theme/brand_typography.dart';
import '../../../auth/domain/usecases/helper_logout_usecase.dart';
import '../../../helper_bookings/presentation/cubit/helper_dashboard_cubit.dart';
import '../../domain/entities/helper_profile_entity.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../widgets/profile_setting_widgets.dart';

class AccountControlCenterPage extends StatefulWidget {
  const AccountControlCenterPage({super.key});

  @override
  State<AccountControlCenterPage> createState() =>
      _AccountControlCenterPageState();
}

class _AccountControlCenterPageState extends State<AccountControlCenterPage> {
  late final ProfileCubit _profileCubit;
  late final HelperDashboardCubit _dashboardCubit;

  @override
  void initState() {
    super.initState();
    _profileCubit = sl<ProfileCubit>()..fetchProfileBundle();
    _dashboardCubit = sl<HelperDashboardCubit>()..loadOnce();
  }

  @override
  void dispose() {
    _profileCubit.close();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      _profileCubit.fetchProfileBundle(),
      _dashboardCubit.load(silent: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _profileCubit),
        BlocProvider.value(value: _dashboardCubit),
      ],
      child: Scaffold(
        backgroundColor: BrandTokens.bgSoft,
        body: SafeArea(
          bottom: false,
          child: BlocConsumer<ProfileCubit, ProfileState>(
            listenWhen: (a, b) =>
                a.errorMessage != b.errorMessage ||
                a.successMessage != b.successMessage,
            listener: (context, state) {
              final messenger = ScaffoldMessenger.of(context);
              if (state.errorMessage != null) {
                messenger.showSnackBar(SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: BrandTokens.dangerSos,
                  behavior: SnackBarBehavior.floating,
                ));
                context.read<ProfileCubit>().clearMessages();
              } else if (state.successMessage != null) {
                messenger.showSnackBar(SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: BrandTokens.successGreen,
                  behavior: SnackBarBehavior.floating,
                ));
                context.read<ProfileCubit>().clearMessages();
              }
            },
            builder: (context, state) {
              if (state.status == ProfileStatus.loading &&
                  state.profile == null) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: BrandTokens.primaryBlue,
                  ),
                );
              }
              if (state.profile == null) {
                return _ErrorState(onRetry: _profileCubit.fetchProfileBundle);
              }

              final profile = state.profile!;

              return BlocBuilder<HelperDashboardCubit, HelperDashboardState>(
                builder: (context, dashState) {
                  int? tripsCount;
                  double? rating;
                  if (dashState is HelperDashboardLoaded) {
                    tripsCount = dashState.dashboard.completedTripsTotal;
                    if (dashState.dashboard.ratingCount > 0) {
                      rating = dashState.dashboard.rating;
                    }
                  }

                  return RefreshIndicator.adaptive(
                    onRefresh: _refresh,
                    color: BrandTokens.primaryBlue,
                    backgroundColor: Colors.white,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
                      children: [
                        const _ProfileTopBar(),
                        const SizedBox(height: 20),
                        _HeroCard(profile: profile),
                        const SizedBox(height: 16),
                        _ProfileStatsStrip(
                          tripsCount: tripsCount,
                          rating: rating,
                        ),
                        const SizedBox(height: 12),
                        ProfileSettingGroup(
                          title: 'Language & interviews',
                          alignWithParentPadding: true,
                          items: [
                            ProfileSettingItem(
                              icon: Icons.translate_rounded,
                              iconColor: palette.primary,
                              title: 'Language interviews',
                              subtitle:
                                  'Verify languages and certification status',
                              onTap: () {
                                HapticFeedback.selectionClick();
                                context.push(AppRouter.helperLanguageInterview);
                              },
                            ),
                          ],
                        ),
                        ProfileSettingGroup(
                          title: 'Service areas',
                          alignWithParentPadding: true,
                          items: [
                            ProfileSettingItem(
                              icon: Icons.travel_explore_rounded,
                              iconColor: const Color(0xFFFFB020),
                              title: 'Regions',
                              subtitle: 'Manage your coverage areas',
                              onTap: () {
                                HapticFeedback.selectionClick();
                                context.push(AppRouter.helperServiceAreas);
                              },
                            ),
                          ],
                        ),
                        ProfileSettingGroup(
                          title: 'Preferences',
                          alignWithParentPadding: true,
                          items: [
                            ProfileSettingItem(
                              icon: Icons.language_rounded,
                              iconColor: const Color(0xFF00B8A9),
                              title: 'App Language',
                              subtitle: 'English (US)',
                              onTap: () => HapticFeedback.selectionClick(),
                            ),
                            ProfileSettingItem(
                              icon: Icons.notifications_none_rounded,
                              iconColor: const Color(0xFFFF6B9D),
                              title: 'Notifications',
                              subtitle: 'Trip requests and account alerts',
                              onTap: () {
                                HapticFeedback.selectionClick();
                                context.push(AppRouter.helperNotifications);
                              },
                            ),
                            ProfileSettingItem(
                              icon: Icons.dark_mode_outlined,
                              iconColor: const Color(0xFF6C7BFF),
                              title: 'Theme & Appearance',
                              subtitle: palette.isDark
                                  ? 'Dark mode'
                                  : 'Light mode',
                              onTap: () => HapticFeedback.selectionClick(),
                            ),
                          ],
                        ),
                        ProfileSettingGroup(
                          title: 'Security',
                          alignWithParentPadding: true,
                          items: [
                            ProfileSettingItem(
                              icon: Icons.lock_outline_rounded,
                              iconColor: palette.danger,
                              title: 'Change Password',
                              subtitle: 'Update your password',
                              onTap: () => HapticFeedback.selectionClick(),
                            ),
                            ProfileSettingItem(
                              icon: Icons.fingerprint_rounded,
                              iconColor: palette.primary,
                              title: 'Biometric Login',
                              subtitle: 'Face ID / Fingerprint',
                              trailing: Switch(
                                value: true,
                                onChanged: (_) =>
                                    HapticFeedback.mediumImpact(),
                              ),
                            ),
                          ],
                        ),
                        ProfileSettingGroup(
                          title: 'Support',
                          alignWithParentPadding: true,
                          items: [
                            ProfileSettingItem(
                              icon: Icons.help_center_outlined,
                              iconColor: palette.primary,
                              title: 'Help Center',
                              subtitle: 'FAQ & guides',
                              onTap: () => HapticFeedback.selectionClick(),
                            ),
                            ProfileSettingItem(
                              icon: Icons.report_problem_outlined,
                              iconColor: const Color(0xFFFFB020),
                              title: 'Resolution Center',
                              subtitle: 'View your reports & resolutions',
                              onTap: () {
                                HapticFeedback.selectionClick();
                                context.push(AppRouter.helperReports);
                              },
                            ),
                            ProfileSettingItem(
                              icon: Icons.policy_outlined,
                              iconColor: palette.textSecondary,
                              title: 'Terms & Privacy',
                              subtitle: 'Legal information',
                              onTap: () => HapticFeedback.selectionClick(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        _SignOutButton(
                          onLogout: () => _confirmLogout(context),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'RAFIQ — Your Way, Your Tour.',
                            style: BrandTypography.caption(
                              color: BrandTokens.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    HapticFeedback.lightImpact();
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(loc.translate('logout')),
          content: Text(loc.translate('logout_confirmation')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(loc.translate('cancel')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: BrandTokens.dangerSos,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(loc.translate('logout')),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await sl<HelperLogoutUseCase>()();
    } catch (_) {
      // Best-effort logout — we still navigate away regardless.
    }
    if (!context.mounted) return;
    context.go(AppRouter.roleSelection);
  }
}

// ============================================================================
//  TOP BAR (RAFIQ wordmark + explore icon)
// ============================================================================

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 40),
          const Spacer(),
          Text(
            BrandTokens.wordmark,
            style: BrandTokens.heading(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: BrandTokens.primaryBlue,
              letterSpacing: -0.6,
            ),
          ),
          const Spacer(),
          _IconCircleButton(
            icon: Icons.explore_outlined,
            onTap: () => HapticFeedback.selectionClick(),
          ),
        ],
      ),
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(icon, color: BrandTokens.primaryBlue, size: 24),
        ),
      ),
    );
  }
}

// ============================================================================
//  HERO CARD (avatar + name + email)
// ============================================================================

class _HeroCard extends StatelessWidget {
  final HelperProfileEntity profile;

  const _HeroCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = _displayName(profile);
    final email = profile.email.isNotEmpty ? profile.email : '—';
    final initial = _initialOf(profile);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          context.push(AppRouter.helperProfileView);
        },
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            color: BrandTokens.surfaceWhite,
            borderRadius: BorderRadius.circular(28),
            boxShadow: BrandTokens.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              children: [
                _BigAvatar(
                  url: profile.profileImageUrl,
                  initial: initial,
                  isApproved: profile.isApproved,
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: BrandTokens.heading(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: BrandTokens.primaryBlue,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: BrandTypography.caption(color: BrandTokens.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                _VerifiedStatus(isApproved: profile.isApproved),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BigAvatar extends StatelessWidget {
  final String? url;
  final String initial;
  final bool isApproved;

  const _BigAvatar({
    required this.url,
    required this.initial,
    required this.isApproved,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            gradient: BrandTokens.primaryGradient,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: const [
              BoxShadow(
                color: BrandTokens.glowBlue,
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: _AvatarImage(url: url, initial: initial, fontSize: 32),
        ),
        if (isApproved)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 12,
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
        border: Border.all(color: color.withValues(alpha: 0.30), width: 0.6),
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

class _AvatarImage extends StatelessWidget {
  final String? url;
  final String initial;
  final double fontSize;

  const _AvatarImage({
    required this.url,
    required this.initial,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Text(
        initial,
        style: BrandTokens.heading(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );

    final imageUrl = url;
    if (imageUrl == null || imageUrl.isEmpty) return fallback;

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => fallback,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return fallback;
      },
    );
  }
}

// ============================================================================
//  ACTIVITY STATS (trips + rating)
// ============================================================================

class _ProfileStatsStrip extends StatelessWidget {
  final int? tripsCount;
  final double? rating;

  const _ProfileStatsStrip({
    required this.tripsCount,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          child: _ProfileStatTile(
            icon: Icons.luggage_rounded,
            label: loc.translate('profile_trips'),
            value: tripsCount?.toString() ?? '—',
            color: BrandTokens.primaryBlue,
            onTap: () {
              HapticFeedback.selectionClick();
              context.goNamed('helper-bookings');
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ProfileStatTile(
            icon: Icons.star_rounded,
            label: loc.translate('profile_rating'),
            value: _displayRating(rating),
            color: const Color(0xFFFFB020),
          ),
        ),
      ],
    );
  }
}

class _ProfileStatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _ProfileStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandTokens.borderSoft),
        boxShadow: BrandTokens.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: BrandTypography.title(
                    weight: FontWeight.w800,
                  ).copyWith(fontSize: 15, height: 1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: BrandTypography.overline(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return tile;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: tile,
      ),
    );
  }
}

// ============================================================================
//  SIGN OUT
// ============================================================================

class _SignOutButton extends StatelessWidget {
  final VoidCallback onLogout;
  const _SignOutButton({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Center(
      child: TextButton(
        onPressed: onLogout,
        style: TextButton.styleFrom(
          foregroundColor: BrandTokens.dangerSos,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        ),
        child: Text(
          loc.translate('sign_out'),
          style: BrandTypography.body(
            weight: FontWeight.w600,
            color: BrandTokens.dangerSos,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
//  ERROR STATE
// ============================================================================

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: BrandTokens.dangerSos.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: BrandTokens.dangerSos,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Couldn\'t load your profile',
              style: BrandTokens.heading(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: BrandTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: BrandTypography.body(color: BrandTokens.textMuted),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
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

// ============================================================================
//  SHARED HELPERS
// ============================================================================

String _displayName(HelperProfileEntity profile) {
  if (profile.fullName.trim().isNotEmpty) return profile.fullName.trim();
  if (profile.email.contains('@')) return profile.email.split('@').first;
  return 'Helper';
}

String _initialOf(HelperProfileEntity profile) {
  final name = _displayName(profile);
  if (name.isEmpty) return 'H';
  return name[0].toUpperCase();
}

String _displayRating(double? rating) {
  if (rating == null) return '—';
  if (rating == 0) return '4.6';
  return rating.toStringAsFixed(1);
}
