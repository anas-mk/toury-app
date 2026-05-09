import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/config/api_config.dart';
import '../../../../../../core/services/haptic_service.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/animations/fade_in_slide.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/car_entity.dart';
import '../../domain/entities/certificate_entity.dart';
import '../../domain/entities/helper_profile_entity.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../widgets/profile_info/profile_info_form.dart';
import '../widgets/profile_setting_widgets.dart';
import 'identity_verification_page.dart';
import 'vehicle_management_page.dart';

/// Read-only "About me" page summarizing every piece of data we have
/// on the helper. Reachable from the Account Control Center hero card.
class HelperProfileViewPage extends StatelessWidget {
  const HelperProfileViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return Scaffold(
      backgroundColor: palette.scaffold,
      body: BlocBuilder<ProfileCubit, ProfileState>(
        buildWhen: (p, c) => p.profile != c.profile || p.status != c.status,
        builder: (context, state) {
          final profile = state.profile;
          if (profile == null) {
            return Center(
              child: CircularProgressIndicator(color: palette.primary),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<ProfileCubit>().fetchProfileBundle(),
            color: palette.primary,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                _SliverHero(profile: profile),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverList.list(
                    children: [
                      FadeInSlide(
                        child: _PersonalInfoCard(profile: profile),
                      ),
                      const SizedBox(height: 16),
                      FadeInSlide(
                        delay: const Duration(milliseconds: 80),
                        child: _AccountStatusCard(profile: profile),
                      ),
                      if ((profile.selfieImageUrl ?? '').isNotEmpty) ...[
                        const SizedBox(height: 16),
                        FadeInSlide(
                          delay: const Duration(milliseconds: 140),
                          child: _SelfieCard(
                            url: profile.selfieImageUrl!,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FadeInSlide(
                        delay: const Duration(milliseconds: 200),
                        child: _VehicleCard(car: profile.car),
                      ),
                      const SizedBox(height: 16),
                      FadeInSlide(
                        delay: const Duration(milliseconds: 260),
                        child: _CertificatesCard(
                          certificates: profile.certificates,
                        ),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: FadeInSlide(
                    delay: const Duration(milliseconds: 320),
                    child: _ManageSection(profile: profile),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  HERO
// ──────────────────────────────────────────────────────────────────────────────

class _SliverHero extends StatelessWidget {
  final HelperProfileEntity profile;

  const _SliverHero({required this.profile});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 270,
      backgroundColor: palette.scaffold,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: palette.textPrimary,
        ),
        onPressed: () {
          HapticService.light();
          context.pop();
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(56, 0, 20, 14),
        title: Text(
          'My Profile',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        background: _HeroBackground(profile: profile),
      ),
    );
  }
}

class _HeroBackground extends StatelessWidget {
  final HelperProfileEntity profile;

  const _HeroBackground({required this.profile});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    final c1 = palette.primary;
    final c2 = const Color(0xFF7B61FF);

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  c1.withValues(alpha: palette.isDark ? 0.32 : 0.20),
                  c2.withValues(alpha: palette.isDark ? 0.20 : 0.10),
                  palette.scaffold,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
        Positioned(top: -40, right: -30, child: _Orb(color: c1, size: 200)),
        Positioned(bottom: -30, left: -50, child: _Orb(color: c2, size: 160)),
        Positioned(
          left: 20,
          right: 20,
          bottom: 50,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _LargeAvatar(profile: profile),
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
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StatusPill(
                      isApproved: profile.isApproved,
                      isActive: profile.isActive,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LargeAvatar extends StatelessWidget {
  final HelperProfileEntity profile;

  const _LargeAvatar({required this.profile});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final url = ApiConfig.resolveImageUrl(profile.profileImageUrl);
    final hasImage = url.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                palette.primary,
                const Color(0xFF7B61FF),
                const Color(0xFFFF8C42),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: palette.primary.withValues(alpha: 0.30),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.scaffold,
            ),
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.primary.withValues(alpha: 0.10),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasImage
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person_rounded,
                        color: palette.primary,
                        size: 38,
                      ),
                    )
                  : Icon(
                      Icons.person_rounded,
                      color: palette.primary,
                      size: 38,
                    ),
            ),
          ),
        ),
        if (profile.isApproved)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(color: palette.scaffold, width: 2.5),
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

class _Orb extends StatelessWidget {
  final Color color;
  final double size;

  const _Orb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.30),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isApproved;
  final bool isActive;

  const _StatusPill({required this.isApproved, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final color = !isActive
        ? palette.danger
        : isApproved
            ? palette.success
            : const Color(0xFFFFB020);
    final label = !isActive
        ? 'Inactive'
        : isApproved
            ? 'Verified Helper'
            : 'Pending Review';
    final icon = !isActive
        ? Icons.do_disturb_alt_rounded
        : isApproved
            ? Icons.verified_rounded
            : Icons.hourglass_top_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: palette.isDark ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  PERSONAL INFO
// ──────────────────────────────────────────────────────────────────────────────

class _PersonalInfoCard extends StatelessWidget {
  final HelperProfileEntity profile;

  const _PersonalInfoCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return _SectionCard(
      title: 'Personal Information',
      icon: Icons.person_outline_rounded,
      iconColor: palette.primary,
      children: [
        _InfoRow(
          icon: Icons.badge_outlined,
          label: 'Full name',
          value: profile.fullName.isNotEmpty ? profile.fullName : '—',
        ),
        _InfoRow(
          icon: Icons.email_outlined,
          label: 'Email',
          value: profile.email,
          copyable: true,
        ),
        _InfoRow(
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: profile.phoneNumber.isNotEmpty ? profile.phoneNumber : '—',
          copyable: profile.phoneNumber.isNotEmpty,
        ),
        _InfoRow(
          icon: Icons.transgender_rounded,
          label: 'Gender',
          value: _formatGender(profile.gender),
        ),
        _InfoRow(
          icon: Icons.cake_outlined,
          label: 'Birth date',
          value: profile.birthDate != null
              ? '${_formatDate(profile.birthDate!)} · ${_age(profile.birthDate!)} years old'
              : '—',
        ),
        _InfoRow(
          icon: Icons.fingerprint_rounded,
          label: 'Helper ID',
          value: profile.helperId,
          copyable: profile.helperId.isNotEmpty,
          mono: true,
        ),
      ],
    );
  }

  String _formatGender(String g) {
    final v = g.trim().toUpperCase();
    if (v == 'MALE') return 'Male';
    if (v == 'FEMALE') return 'Female';
    return g.isNotEmpty ? g : '—';
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  int _age(DateTime birth) {
    final now = DateTime.now();
    var years = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      years -= 1;
    }
    return years;
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  ACCOUNT STATUS
// ──────────────────────────────────────────────────────────────────────────────

class _AccountStatusCard extends StatelessWidget {
  final HelperProfileEntity profile;

  const _AccountStatusCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return _SectionCard(
      title: 'Account Status',
      icon: Icons.shield_outlined,
      iconColor: palette.success,
      children: [
        _StatusRow(
          icon: Icons.verified_user_outlined,
          label: 'Identity verification',
          ok: profile.isApproved,
          okLabel: 'Approved',
          notOkLabel: 'Pending review',
        ),
        _StatusRow(
          icon: Icons.toggle_on_rounded,
          label: 'Account state',
          ok: profile.isActive,
          okLabel: 'Active',
          notOkLabel: 'Inactive',
        ),
        _InfoRow(
          icon: Icons.timeline_rounded,
          label: 'Onboarding stage',
          value: _formatOnboarding(profile.onboardingStatus),
        ),
      ],
    );
  }

  String _formatOnboarding(String s) {
    if (s.isEmpty) return '—';
    final cleaned = s.replaceAll('_', ' ').toLowerCase();
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  SELFIE
// ──────────────────────────────────────────────────────────────────────────────

class _SelfieCard extends StatelessWidget {
  final String url;

  const _SelfieCard({required this.url});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    final resolved = ApiConfig.resolveImageUrl(url);

    return _SectionCard(
      title: 'Verification Selfie',
      icon: Icons.face_retouching_natural_rounded,
      iconColor: const Color(0xFF7B61FF),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 160,
            color: palette.surfaceInset,
            child: Image.network(
              resolved,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.broken_image_rounded,
                      color: palette.textMuted,
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Image unavailable',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  VEHICLE
// ──────────────────────────────────────────────────────────────────────────────

class _VehicleCard extends StatelessWidget {
  final CarEntity? car;

  const _VehicleCard({required this.car});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    if (car == null) {
      return _SectionCard(
        title: 'Vehicle',
        icon: Icons.directions_car_filled_outlined,
        iconColor: const Color(0xFF7B61FF),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: palette.surfaceInset,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.border, width: 0.6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.no_crash_outlined,
                  color: palette.textMuted,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No vehicle on file yet.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final c = car!;

    return _SectionCard(
      title: 'Vehicle',
      icon: Icons.directions_car_filled_outlined,
      iconColor: const Color(0xFF7B61FF),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF7B61FF).withValues(
                  alpha: palette.isDark ? 0.20 : 0.10,
                ),
                const Color(0xFF7B61FF).withValues(
                  alpha: palette.isDark ? 0.10 : 0.04,
                ),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF7B61FF).withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: palette.isDark ? 0.10 : 0.50,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: Color(0xFF7B61FF),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${c.brand} ${c.model}'.trim(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [c.color, c.carType].where((s) => s.isNotEmpty).join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _InfoRow(
          icon: Icons.confirmation_number_outlined,
          label: 'License plate',
          value: c.licensePlate.isNotEmpty ? c.licensePlate : '—',
          copyable: c.licensePlate.isNotEmpty,
          mono: true,
        ),
        _InfoRow(
          icon: Icons.local_gas_station_outlined,
          label: 'Energy type',
          value: _format(c.energyType),
        ),
        _InfoRow(
          icon: Icons.directions_car_outlined,
          label: 'Body type',
          value: _format(c.carType),
        ),
      ],
    );
  }

  String _format(String s) {
    if (s.isEmpty) return '—';
    final v = s.replaceAll('_', ' ').toLowerCase();
    return v[0].toUpperCase() + v.substring(1);
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  CERTIFICATES
// ──────────────────────────────────────────────────────────────────────────────

class _CertificatesCard extends StatelessWidget {
  final List<CertificateEntity> certificates;

  const _CertificatesCard({required this.certificates});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return _SectionCard(
      title: 'Certificates · ${certificates.length}',
      icon: Icons.workspace_premium_outlined,
      iconColor: const Color(0xFFFF8C42),
      children: certificates.isEmpty
          ? [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceInset,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.border, width: 0.6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: palette.textMuted,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No certificates uploaded yet.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]
          : [
              for (var i = 0; i < certificates.length; i++) ...[
                _CertTile(cert: certificates[i]),
                if (i < certificates.length - 1)
                  const SizedBox(height: 10),
              ],
            ],
    );
  }
}

class _CertTile extends StatelessWidget {
  final CertificateEntity cert;

  const _CertTile({required this.cert});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    const accent = Color(0xFFFF8C42);

    final issued = cert.issueDate != null ? _fmt(cert.issueDate!) : null;
    final expires = cert.expiryDate != null ? _fmt(cert.expiryDate!) : null;
    final isExpired = cert.expiryDate != null
        ? cert.expiryDate!.isBefore(DateTime.now())
        : false;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border, width: 0.6),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: palette.isDark ? 0.28 : 0.18),
                  accent.withValues(alpha: palette.isDark ? 0.14 : 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accent.withValues(alpha: 0.30),
                width: 0.8,
              ),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cert.name.isNotEmpty ? cert.name : 'Certificate',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if ((cert.issuingOrganization ?? '').isNotEmpty)
                      cert.issuingOrganization!,
                    if (issued != null) 'Issued $issued',
                    if (expires != null)
                      '${isExpired ? 'Expired' : 'Expires'} $expires',
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isExpired
                        ? palette.danger
                        : palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  MANAGE SECTION
// ──────────────────────────────────────────────────────────────────────────────

class _ManageSection extends StatelessWidget {
  final HelperProfileEntity profile;

  const _ManageSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final cubit = context.read<ProfileCubit>();

    return ProfileSettingGroup(
      title: 'Account & Identity',
      items: [
        ProfileSettingItem(
          icon: Icons.person_outline_rounded,
          iconColor: palette.primary,
          title: 'Basic Information',
          subtitle: 'Name, phone, birthday',
          onTap: () {
            HapticService.light();
            ProfileInfoForm.show(context, profile);
          },
        ),
        ProfileSettingItem(
          icon: Icons.verified_user_outlined,
          iconColor: palette.success,
          title: 'Identity Verification',
          subtitle: 'Documents, status, selfie',
          badge: profile.isApproved ? 'Verified' : 'Pending',
          badgeColor: profile.isApproved ? palette.success : palette.warning,
          onTap: () {
            HapticService.light();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: cubit,
                  child: IdentityVerificationPage(profile: profile),
                ),
              ),
            );
          },
        ),
        ProfileSettingItem(
          icon: Icons.directions_car_filled_outlined,
          iconColor: const Color(0xFF7B61FF),
          title: 'Vehicle Management',
          subtitle: profile.car != null
              ? '${profile.car!.brand} ${profile.car!.model}'
              : 'No vehicle added',
          onTap: () {
            HapticService.light();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VehicleManagementPage(car: profile.car),
              ),
            );
          },
        ),
        ProfileSettingItem(
          icon: Icons.workspace_premium_outlined,
          iconColor: const Color(0xFFFF8C42),
          title: 'Certificates & Languages',
          subtitle: '${profile.certificates.length} certificates',
          onTap: () => HapticService.light(),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  SHARED PIECES
// ──────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border, width: 0.6),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: palette.isDark ? 0.10 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      iconColor.withValues(
                        alpha: palette.isDark ? 0.28 : 0.18,
                      ),
                      iconColor.withValues(
                        alpha: palette.isDark ? 0.14 : 0.08,
                      ),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool copyable;
  final bool mono;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: palette.textMuted, size: 16),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.textPrimary,
                fontWeight: FontWeight.w700,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
          if (copyable)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    HapticService.light();
                    await Clipboard.setData(ClipboardData(text: value));
                    if (!context.mounted) return;
                    AppSnackbar.show(
                      context,
                      message: '$label copied',
                      tone: AppSnackTone.success,
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: palette.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool ok;
  final String okLabel;
  final String notOkLabel;

  const _StatusRow({
    required this.icon,
    required this.label,
    required this.ok,
    required this.okLabel,
    required this.notOkLabel,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    final color = ok ? palette.success : const Color(0xFFFFB020);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, color: palette.textMuted, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: palette.isDark ? 0.22 : 0.14),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: color.withValues(alpha: 0.30),
                width: 0.6,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  ok
                      ? Icons.check_circle_rounded
                      : Icons.hourglass_top_rounded,
                  color: color,
                  size: 12,
                ),
                const SizedBox(width: 5),
                Text(
                  ok ? okLabel : notOkLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
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
