import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/animations/fade_in_slide.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../domain/entities/helper_profile_entity.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../widgets/car/car_management_card.dart';
import '../widgets/certificates/certificates_list.dart';
import '../widgets/documents/documents_checklist.dart';
import '../widgets/eligibility/eligibility_alert.dart';
import '../widgets/images/image_management_card.dart';
import '../widgets/onboarding/onboarding_progress_card.dart';
import '../widgets/profile_info/profile_info_form.dart';
import '../widgets/status/profile_status_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return BlocProvider<ProfileCubit>(
      create: (context) => sl<ProfileCubit>()..fetchProfileBundle(),
      child: Scaffold(
        backgroundColor: palette.scaffold,
        body: BlocConsumer<ProfileCubit, ProfileState>(
          listenWhen: (previous, current) =>
              previous.successMessage != current.successMessage ||
              previous.errorMessage != current.errorMessage,
          listener: (context, state) {
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: palette.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              );
              context.read<ProfileCubit>().clearMessages();
            } else if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: palette.danger,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              );
              context.read<ProfileCubit>().clearMessages();
            }
          },
          builder: (context, state) {
            if (state.status == ProfileStatus.initial ||
                (state.status == ProfileStatus.loading && state.profile == null)) {
              return Center(child: CircularProgressIndicator(color: palette.primary));
            }

            if (state.profile == null) {
              return _ErrorState(
                onRetry: () => context.read<ProfileCubit>().fetchProfileBundle(),
              );
            }

            final profile = state.profile!;
            final eligibilityRecord = state.eligibilityRecord;
            final statusRecord = state.statusRecord;

            return RefreshIndicator(
              onRefresh: () async {
                await context.read<ProfileCubit>().fetchProfileBundle();
              },
              color: palette.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(
                    child: FadeInSlide(
                      duration: const Duration(milliseconds: 500),
                      child: _ProfileHero(profile: profile),
                    ),
                  ),

                  if (eligibilityRecord != null && !eligibilityRecord.isEligible)
                    SliverToBoxAdapter(
                      child: FadeInSlide(
                        delay: const Duration(milliseconds: 80),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: EligibilityAlert(eligibility: eligibilityRecord),
                        ),
                      ),
                    ),

                  SliverToBoxAdapter(
                    child: FadeInSlide(
                      delay: const Duration(milliseconds: 120),
                      child: _SectionWrapper(
                        title: 'Onboarding Progress',
                        subtitle: 'Complete each step to get verified',
                        child: OnboardingProgressCard(profile: profile),
                      ),
                    ),
                  ),

                  if (statusRecord != null)
                    SliverToBoxAdapter(
                      child: FadeInSlide(
                        delay: const Duration(milliseconds: 160),
                        child: _SectionWrapper(
                          title: 'Account Status',
                          subtitle: 'Current state of your account',
                          child: ProfileStatusCard(
                            status: statusRecord,
                            onSubmitForReview: () {},
                          ),
                        ),
                      ),
                    ),

                  SliverToBoxAdapter(
                    child: FadeInSlide(
                      delay: const Duration(milliseconds: 200),
                      child: _SectionWrapper(
                        title: 'Photos',
                        subtitle: 'Profile and selfie verification',
                        child: ImageManagementCard(profile: profile),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: FadeInSlide(
                      delay: const Duration(milliseconds: 240),
                      child: _SectionWrapper(
                        title: 'Documents',
                        subtitle: 'Required verification documents',
                        child: const DocumentsChecklist(),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: FadeInSlide(
                      delay: const Duration(milliseconds: 280),
                      child: _SectionWrapper(
                        title: 'Vehicle',
                        subtitle: 'Your registered vehicle information',
                        child: CarManagementCard(car: profile.car),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: FadeInSlide(
                      delay: const Duration(milliseconds: 320),
                      child: _SectionWrapper(
                        title: 'Certificates',
                        subtitle: 'Languages and professional credentials',
                        child: CertificatesList(certificates: profile.certificates),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  HERO HEADER
// ──────────────────────────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  final HelperProfileEntity profile;
  const _ProfileHero({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final isDark = palette.isDark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    palette.primary.withValues(alpha: 0.30),
                    palette.primaryStrong.withValues(alpha: 0.18),
                    const Color(0xFF7B61FF).withValues(alpha: 0.18),
                  ]
                : [
                    palette.primary.withValues(alpha: 0.95),
                    palette.primaryStrong.withValues(alpha: 0.85),
                    const Color(0xFF7B61FF).withValues(alpha: 0.85),
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withValues(alpha: isDark ? 0.20 : 0.30),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -20,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Avatar(profile: profile),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              profile.fullName.isNotEmpty
                                  ? profile.fullName
                                  : 'Helper Profile',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile.email,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            _StatusPill(profile: profile),
                          ],
                        ),
                      ),
                      _GlassIconButton(
                        icon: Icons.edit_outlined,
                        onTap: () => ProfileInfoForm.show(context, profile),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          label: 'Phone',
                          value: profile.phoneNumber.isNotEmpty
                              ? profile.phoneNumber
                              : '—',
                          icon: Icons.phone_iphone_rounded,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                      Expanded(
                        child: _MiniStat(
                          label: 'Gender',
                          value: profile.gender.isNotEmpty ? profile.gender : '—',
                          icon: Icons.person_outline_rounded,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                      Expanded(
                        child: _MiniStat(
                          label: 'Certs',
                          value: '${profile.certificates.length}',
                          icon: Icons.workspace_premium_outlined,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFFFE4B2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            backgroundImage: (profile.profileImageUrl != null && profile.profileImageUrl!.isNotEmpty)
                ? NetworkImage(profile.profileImageUrl!)
                : null,
            child: (profile.profileImageUrl == null || profile.profileImageUrl!.isEmpty)
                ? const Icon(Icons.person_rounded, color: AppColor.primaryColor, size: 34)
                : null,
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
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 11),
            ),
          ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final HelperProfileEntity profile;
  const _StatusPill({required this.profile});

  @override
  Widget build(BuildContext context) {
    String text;
    IconData icon;

    if (profile.isApproved) {
      text = 'PRO HELPER · VERIFIED';
      icon = Icons.verified_rounded;
    } else if (profile.onboardingStatus == 'REJECTED') {
      text = 'NEEDS ATTENTION';
      icon = Icons.error_outline_rounded;
    } else {
      text = 'PENDING REVIEW';
      icon = Icons.shield_outlined;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.30),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 13),
              const SizedBox(width: 6),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
              ),
              child: Icon(icon, color: Colors.white, size: 17),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  SECTION WRAPPER
// ──────────────────────────────────────────────────────────────────────────────

class _SectionWrapper extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionWrapper({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: palette.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
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
