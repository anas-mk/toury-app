import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/config/api_config.dart';
import '../../../../../../core/router/app_router.dart';
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

String _formatShortDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

String _formatOnboardingLabel(String s) {
  if (s.isEmpty) return '—';
  final cleaned = s.replaceAll('_', ' ').toLowerCase();
  return cleaned[0].toUpperCase() + cleaned.substring(1);
}

String _formatGenderLabel(String g) {
  final v = g.trim().toUpperCase();
  if (v == 'MALE') return 'Male';
  if (v == 'FEMALE') return 'Female';
  return g.isNotEmpty ? g : '—';
}

int _ageFromBirth(DateTime birth) {
  final now = DateTime.now();
  var years = now.year - birth.year;
  if (now.month < birth.month ||
      (now.month == birth.month && now.day < birth.day)) {
    years -= 1;
  }
  return years;
}

String _formatEnumLabel(String s) {
  if (s.isEmpty) return '—';
  final v = s.replaceAll('_', ' ').toLowerCase();
  return v[0].toUpperCase() + v.substring(1);
}

/// Read-only summary of helper profile data. Opened from **Account → profile card**
/// (`/helper/profile-view`) for a focused view of identity and vehicle records.
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

          final profileImg = ApiConfig.resolveImageUrl(profile.profileImageUrl);
          final selfieRaw = profile.selfieImageUrl ?? '';
          final selfieResolved = ApiConfig.resolveImageUrl(selfieRaw);
          final showSelfie = selfieRaw.isNotEmpty &&
              selfieResolved.isNotEmpty &&
              selfieResolved != profileImg;

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<ProfileCubit>().fetchProfileBundle(),
            color: palette.primary,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                _ProfileAppBar(profile: profile),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  sliver: SliverList.list(
                    children: [
                      FadeInSlide(
                        child: _PersonalDetailsCard(profile: profile),
                      ),
                      if (showSelfie) ...[
                        const SizedBox(height: 14),
                        FadeInSlide(
                          delay: const Duration(milliseconds: 60),
                          child: _VerificationPhotoCard(url: selfieRaw),
                        ),
                      ],
                      const SizedBox(height: 14),
                      FadeInSlide(
                        delay: const Duration(milliseconds: 80),
                        child: _VehicleSection(car: profile.car),
                      ),
                      const SizedBox(height: 14),
                      FadeInSlide(
                        delay: const Duration(milliseconds: 100),
                        child: _CertificatesSection(
                          certificates: profile.certificates,
                        ),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: FadeInSlide(
                    delay: const Duration(milliseconds: 120),
                    child: _ActionsSection(profile: profile),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── App bar + header ─────────────────────────────────────────────────────────

class _ProfileAppBar extends StatelessWidget {
  final HelperProfileEntity profile;

  const _ProfileAppBar({required this.profile});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 168,
      backgroundColor: palette.scaffold,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: palette.textPrimary,
          size: 20,
        ),
        onPressed: () {
          HapticService.light();
          context.pop();
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(52, 0, 16, 12),
        title: Text(
          'Profile',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        background: _HeaderBackdrop(profile: profile),
      ),
    );
  }
}

class _HeaderBackdrop extends StatelessWidget {
  final HelperProfileEntity profile;

  const _HeaderBackdrop({required this.profile});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                palette.primary.withValues(alpha: palette.isDark ? 0.14 : 0.08),
                palette.scaffold,
              ],
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 44,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Avatar(profile: profile),
              const SizedBox(width: 14),
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
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                        fontSize: 20,
                        letterSpacing: -0.3,
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
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _StatusChip(
                          label: !profile.isActive
                              ? 'Inactive'
                              : profile.isApproved
                                  ? 'Verified'
                                  : 'Pending review',
                          tone: !profile.isActive
                              ? _ChipTone.danger
                              : profile.isApproved
                                  ? _ChipTone.success
                                  : _ChipTone.warning,
                          icon: !profile.isActive
                              ? Icons.pause_circle_outline_rounded
                              : profile.isApproved
                                  ? Icons.verified_outlined
                                  : Icons.schedule_rounded,
                        ),
                        if (profile.onboardingStatus.isNotEmpty)
                          _StatusChip(
                            label: _formatOnboardingLabel(
                              profile.onboardingStatus,
                            ),
                            tone: _ChipTone.neutral,
                            icon: Icons.flag_outlined,
                          ),
                      ],
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

enum _ChipTone { success, warning, danger, neutral }

class _StatusChip extends StatelessWidget {
  final String label;
  final _ChipTone tone;
  final IconData icon;

  const _StatusChip({
    required this.label,
    required this.tone,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final Color fg;
    final Color bg;
    switch (tone) {
      case _ChipTone.success:
        fg = palette.success;
        bg = palette.success.withValues(alpha: palette.isDark ? 0.2 : 0.12);
      case _ChipTone.warning:
        fg = palette.warning;
        bg = palette.warning.withValues(alpha: palette.isDark ? 0.2 : 0.12);
      case _ChipTone.danger:
        fg = palette.danger;
        bg = palette.danger.withValues(alpha: palette.isDark ? 0.2 : 0.12);
      case _ChipTone.neutral:
        fg = palette.textSecondary;
        bg = palette.surfaceInset;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: fg.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
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
    final url = ApiConfig.resolveImageUrl(profile.profileImageUrl);
    final hasImage = url.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.surface,
            border: Border.all(color: palette.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: palette.isDark ? 0.35 : 0.06,
                ),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: hasImage
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.person_rounded,
                    color: palette.textMuted,
                    size: 34,
                  ),
                )
              : Icon(
                  Icons.person_rounded,
                  color: palette.textMuted,
                  size: 34,
                ),
        ),
        if (profile.isApproved)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: palette.success,
                shape: BoxShape.circle,
                border: Border.all(color: palette.scaffold, width: 2),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 11,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Sections ─────────────────────────────────────────────────────────────────

class _PersonalDetailsCard extends StatelessWidget {
  final HelperProfileEntity profile;

  const _PersonalDetailsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      title: 'Details',
      child: Column(
        children: [
          _DetailTile(
            icon: Icons.badge_outlined,
            label: 'Full name',
            value: profile.fullName.isNotEmpty ? profile.fullName : '—',
          ),
          _tileDivider(context),
          _DetailTile(
            icon: Icons.email_outlined,
            label: 'Email',
            value: profile.email,
            copyable: true,
          ),
          _tileDivider(context),
          _DetailTile(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: profile.phoneNumber.isNotEmpty ? profile.phoneNumber : '—',
            copyable: profile.phoneNumber.isNotEmpty,
          ),
          _tileDivider(context),
          _DetailTile(
            icon: Icons.transgender_rounded,
            label: 'Gender',
            value: _formatGenderLabel(profile.gender),
          ),
          _tileDivider(context),
          _DetailTile(
            icon: Icons.cake_outlined,
            label: 'Birth date',
            value: profile.birthDate != null
                ? '${_formatShortDate(profile.birthDate!)} · ${_ageFromBirth(profile.birthDate!)} yrs'
                : '—',
          ),
          _tileDivider(context),
          _DetailTile(
            icon: Icons.fingerprint_rounded,
            label: 'Helper ID',
            value: profile.helperId,
            copyable: profile.helperId.isNotEmpty,
            mono: true,
          ),
        ],
      ),
    );
  }
}

Widget _tileDivider(BuildContext context) {
  final palette = AppColors.of(context);
  return Padding(
    padding: const EdgeInsets.only(left: 44),
    child: Divider(height: 1, thickness: 0.5, color: palette.border),
  );
}

class _VerificationPhotoCard extends StatelessWidget {
  final String url;

  const _VerificationPhotoCard({required this.url});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    final resolved = ApiConfig.resolveImageUrl(url);

    return _SurfaceCard(
      title: 'Verification photo',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Image.network(
            resolved,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: palette.surfaceInset,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.hide_image_outlined,
                      color: palette.textMuted,
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Unavailable',
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
      ),
    );
  }
}

class _VehicleSection extends StatelessWidget {
  final CarEntity? car;

  const _VehicleSection({required this.car});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    if (car == null) {
      return _SurfaceCard(
        title: 'Vehicle',
        child: Text(
          'No vehicle on file. Add one from the action below.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: palette.textSecondary,
            height: 1.35,
          ),
        ),
      );
    }

    final c = car!;
    return _SurfaceCard(
      title: 'Vehicle',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: palette.surfaceInset,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.directions_car_rounded,
                  color: palette.primary,
                  size: 22,
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
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [c.color, c.carType]
                          .where((s) => s.isNotEmpty)
                          .join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DetailTile(
            icon: Icons.pin_outlined,
            label: 'License plate',
            value: c.licensePlate.isNotEmpty ? c.licensePlate : '—',
            copyable: c.licensePlate.isNotEmpty,
            mono: true,
            dense: true,
          ),
          _tileDivider(context),
          _DetailTile(
            icon: Icons.local_gas_station_outlined,
            label: 'Energy',
            value: _formatEnumLabel(c.energyType),
            dense: true,
          ),
        ],
      ),
    );
  }
}

class _CertificatesSection extends StatelessWidget {
  final List<CertificateEntity> certificates;

  const _CertificatesSection({required this.certificates});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return _SurfaceCard(
      title: 'Certificates (${certificates.length})',
      child: certificates.isEmpty
          ? Text(
              'None uploaded yet. Language verification lives under Interviews.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.textSecondary,
                height: 1.35,
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < certificates.length; i++) ...[
                  _CertificateRow(cert: certificates[i]),
                  if (i < certificates.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

class _CertificateRow extends StatelessWidget {
  final CertificateEntity cert;

  const _CertificateRow({required this.cert});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    final issued = cert.issueDate != null ? _formatShortDate(cert.issueDate!) : null;
    final expires =
        cert.expiryDate != null ? _formatShortDate(cert.expiryDate!) : null;
    final isExpired =
        cert.expiryDate != null && cert.expiryDate!.isBefore(DateTime.now());

    final meta = <String>[
      if ((cert.issuingOrganization ?? '').isNotEmpty)
        cert.issuingOrganization!,
      if (issued != null) 'Issued $issued',
      if (expires != null)
        '${isExpired ? 'Expired' : 'Expires'} $expires',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceInset,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isExpired ? palette.danger : palette.primary,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.workspace_premium_outlined,
            color: isExpired ? palette.danger : palette.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cert.name.isNotEmpty ? cert.name : 'Certificate',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isExpired ? palette.danger : palette.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsSection extends StatelessWidget {
  final HelperProfileEntity profile;

  const _ActionsSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final cubit = context.read<ProfileCubit>();

    return ProfileSettingGroup(
      title: 'Manage',
      items: [
        ProfileSettingItem(
          icon: Icons.edit_outlined,
          iconColor: palette.primary,
          title: 'Edit basic info',
          subtitle: 'Name, phone, birthday',
          onTap: () {
            HapticService.light();
            ProfileInfoForm.show(context, profile);
          },
        ),
        ProfileSettingItem(
          icon: Icons.verified_user_outlined,
          iconColor: palette.success,
          title: 'Identity & documents',
          subtitle: 'Status and uploads',
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
          iconColor: palette.primary,
          title: 'Vehicle',
          subtitle: profile.car != null
              ? '${profile.car!.brand} ${profile.car!.model}'
              : 'Not set',
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
          icon: Icons.translate_rounded,
          iconColor: const Color(0xFF00B8A9),
          title: 'Languages & interviews',
          subtitle: 'Certification and exams',
          onTap: () {
            HapticService.light();
            context.push(AppRouter.helperLanguageInterview);
          },
        ),
      ],
    );
  }
}

// ─── Shared layout ────────────────────────────────────────────────────────────

class _SurfaceCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SurfaceCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool copyable;
  final bool mono;
  final bool dense;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
    this.mono = false,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    final vPad = dense ? 10.0 : 12.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: vPad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: palette.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                    fontFamily: mono ? 'monospace' : null,
                  ),
                ),
              ],
            ),
          ),
          if (copyable)
            IconButton(
              onPressed: () async {
                HapticService.light();
                await Clipboard.setData(ClipboardData(text: value));
                if (!context.mounted) return;
                AppSnackbar.show(
                  context,
                  message: '$label copied',
                  tone: AppSnackTone.success,
                );
              },
              icon: Icon(
                Icons.copy_rounded,
                size: 18,
                color: palette.textMuted,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
            ),
        ],
      ),
    );
  }
}
