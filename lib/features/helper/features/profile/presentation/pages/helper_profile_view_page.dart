import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../../core/config/api_config.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/theme/brand_typography.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/car_entity.dart';
import '../../domain/entities/helper_profile_entity.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../utils/profile_image_helper.dart';
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

/// Read-only helper profile summary — opened from Account → profile card.
class HelperProfileViewPage extends StatelessWidget {
  const HelperProfileViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandTokens.bgSoft,
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listenWhen: (previous, current) =>
            previous.successMessage != current.successMessage ||
            previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          if (state.successMessage != null) {
            AppSnackbar.show(
              context,
              message: state.successMessage!,
              tone: AppSnackTone.success,
            );
            context.read<ProfileCubit>().clearMessages();
          } else if (state.errorMessage != null) {
            AppSnackbar.show(
              context,
              message: state.errorMessage!,
              tone: AppSnackTone.danger,
            );
            context.read<ProfileCubit>().clearMessages();
          }
        },
        buildWhen: (previous, current) =>
            previous.profile != current.profile ||
            previous.status != current.status,
        builder: (context, state) {
          final profile = state.profile;
          if (profile == null) {
            return const Center(
              child: CircularProgressIndicator(color: BrandTokens.primaryBlue),
            );
          }

          final isUploadingImage =
              state.status == ProfileStatus.uploadingImage;

          return RefreshIndicator.adaptive(
            onRefresh: () async =>
                context.read<ProfileCubit>().fetchProfileBundle(),
            color: BrandTokens.primaryBlue,
            backgroundColor: Colors.white,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              children: [
                const _PageHeader(title: 'Profile'),
                const SizedBox(height: 12),
                _HeroCard(
                  profile: profile,
                  isUploadingImage: isUploadingImage,
                ),
                const SizedBox(height: 16),
                _InfoSection(profile: profile),
                if (profile.car != null) ...[
                  const SizedBox(height: 12),
                  _VehicleCard(car: profile.car!),
                ],
                const SizedBox(height: 12),
                _ManageSection(profile: profile),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final String title;

  const _PageHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
        child: SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (canPop)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      context.pop();
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: BrandTokens.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
              Text(
                title,
                style: BrandTypography.title(
                  weight: FontWeight.w800,
                ).copyWith(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final HelperProfileEntity profile;
  final bool isUploadingImage;

  const _HeroCard({
    required this.profile,
    this.isUploadingImage = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = _displayName(profile);
    final email = profile.email.isNotEmpty ? profile.email : '—';
    final initial = _initialOf(profile);
    final imageUrl = ApiConfig.resolveImageUrl(profile.profileImageUrl);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(28),
        boxShadow: BrandTokens.cardShadow,
      ),
      child: Column(
        children: [
          _ProfileAvatar(
            url: imageUrl.isNotEmpty ? imageUrl : null,
            initial: initial,
            isApproved: profile.isApproved,
            isUploading: isUploadingImage,
            onEditTap: isUploadingImage
                ? null
                : () => _showProfileImagePickerSheet(context),
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
          _VerifiedBadge(isApproved: profile.isApproved),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? url;
  final String initial;
  final bool isApproved;
  final bool isUploading;
  final VoidCallback? onEditTap;

  const _ProfileAvatar({
    required this.url,
    required this.initial,
    required this.isApproved,
    this.isUploading = false,
    this.onEditTap,
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
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (url != null)
                Image.network(
                  url!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => _initialFallback(initial),
                )
              else
                _initialFallback(initial),
              if (isUploading)
                Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (onEditTap != null)
          Positioned(
            left: -2,
            bottom: -2,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onEditTap!();
                },
                customBorder: const CircleBorder(),
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: BrandTokens.accentAmber,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
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

  Widget _initialFallback(String initial) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: BrandTokens.primaryGradient,
      ),
      child: Text(
        initial,
        style: BrandTokens.heading(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  final bool isApproved;

  const _VerifiedBadge({required this.isApproved});

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

// ─── Info rows ────────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final HelperProfileEntity profile;

  const _InfoSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    return _BrandCard(
      title: 'Details',
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: profile.phoneNumber.isNotEmpty ? profile.phoneNumber : '—',
            copyable: profile.phoneNumber.isNotEmpty,
          ),
          const _InfoDivider(),
          _InfoRow(
            icon: Icons.transgender_rounded,
            label: 'Gender',
            value: _formatGenderLabel(profile.gender),
          ),
          const _InfoDivider(),
          _InfoRow(
            icon: Icons.cake_outlined,
            label: 'Birth date',
            value: profile.birthDate != null
                ? '${_formatShortDate(profile.birthDate!)} · ${_ageFromBirth(profile.birthDate!)} yrs'
                : '—',
          ),
          const _InfoDivider(),
          _InfoRow(
            icon: Icons.fingerprint_rounded,
            label: 'Helper ID',
            value: profile.helperId.isNotEmpty ? profile.helperId : '—',
            copyable: profile.helperId.isNotEmpty,
            mono: true,
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final CarEntity car;

  const _VehicleCard({required this.car});

  @override
  Widget build(BuildContext context) {
    final subtitle = [car.color, car.carType]
        .where((s) => s.isNotEmpty)
        .join(' · ');

    return _BrandCard(
      title: 'Vehicle',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: BrandTokens.primaryBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: BrandTokens.primaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${car.brand} ${car.model}'.trim(),
                      style: BrandTypography.title(weight: FontWeight.w700),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: BrandTypography.caption(
                          color: BrandTokens.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.pin_outlined,
            label: 'License plate',
            value: car.licensePlate.isNotEmpty ? car.licensePlate : '—',
            copyable: car.licensePlate.isNotEmpty,
            mono: true,
            compact: true,
          ),
          const _InfoDivider(),
          _InfoRow(
            icon: Icons.local_gas_station_outlined,
            label: 'Energy',
            value: _formatEnumLabel(car.energyType),
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _BrandCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _BrandCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BrandTokens.borderSoft),
        boxShadow: BrandTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: BrandTypography.overline(),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _InfoDivider extends StatelessWidget {
  const _InfoDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 36),
      child: Divider(height: 1, thickness: 1, color: BrandTokens.borderSoft),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool copyable;
  final bool mono;
  final bool compact;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
    this.mono = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 8 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: BrandTokens.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: BrandTypography.overline()),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: BrandTypography.body(
                    weight: FontWeight.w600,
                  ).copyWith(
                    fontFamily: mono ? 'monospace' : null,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          if (copyable)
            IconButton(
              onPressed: () async {
                HapticFeedback.selectionClick();
                await Clipboard.setData(ClipboardData(text: value));
                if (!context.mounted) return;
                AppSnackbar.show(
                  context,
                  message: '$label copied',
                  tone: AppSnackTone.success,
                );
              },
              icon: const Icon(
                Icons.copy_rounded,
                size: 18,
                color: BrandTokens.textMuted,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
        ],
      ),
    );
  }
}

// ─── Manage actions ───────────────────────────────────────────────────────────

class _ManageSection extends StatelessWidget {
  final HelperProfileEntity profile;

  const _ManageSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final cubit = context.read<ProfileCubit>();

    return ProfileSettingGroup(
      title: 'Manage',
      alignWithParentPadding: true,
      items: [
        ProfileSettingItem(
          icon: Icons.edit_outlined,
          iconColor: palette.primary,
          title: 'Edit basic info',
          subtitle: 'Name, phone, birthday',
          onTap: () {
            HapticFeedback.selectionClick();
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
            HapticFeedback.selectionClick();
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
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VehicleManagementPage(car: profile.car),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

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

Future<void> _showProfileImagePickerSheet(BuildContext context) {
  final cubit = context.read<ProfileCubit>();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (sheetContext) {
      return BlocProvider.value(
        value: cubit,
        child: const _ProfileImagePickerSheet(),
      );
    },
  );
}

class _ProfileImagePickerSheet extends StatelessWidget {
  const _ProfileImagePickerSheet();

  Future<void> _pick(BuildContext context, ImageSource source) async {
    HapticFeedback.selectionClick();
    final cubit = context.read<ProfileCubit>();

    File? file;
    try {
      file = await ProfileImageHelper.pickAndValidateImage(source);
    } on FormatException catch (e) {
      if (!context.mounted) return;
      AppSnackbar.show(
        context,
        message: e.message,
        tone: AppSnackTone.danger,
      );
      return;
    } catch (_) {
      if (!context.mounted) return;
      AppSnackbar.show(
        context,
        message: 'Could not pick image. Please try again.',
        tone: AppSnackTone.danger,
      );
      return;
    }

    if (!context.mounted) return;
    Navigator.of(context).pop();

    if (file == null) return;

    await cubit.uploadProfileImage(file);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: BrandTokens.borderSoft,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Change profile photo',
              style: BrandTokens.heading(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: BrandTokens.primaryBlue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose a clear photo of yourself. Max size 5 MB.',
              style: BrandTypography.caption(color: BrandTokens.textMuted),
            ),
            const SizedBox(height: 20),
            _PickerOptionRow(
              icon: Icons.photo_camera_rounded,
              label: 'Take photo',
              onTap: () => _pick(context, ImageSource.camera),
            ),
            const SizedBox(height: 10),
            _PickerOptionRow(
              icon: Icons.photo_library_rounded,
              label: 'Choose from gallery',
              onTap: () => _pick(context, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: BrandTokens.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerOptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerOptionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: BrandTokens.bgSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BrandTokens.borderSoft),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: BrandTokens.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: BrandTokens.primaryBlue, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: BrandTypography.body(
                    weight: FontWeight.w600,
                    color: BrandTokens.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: BrandTokens.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
