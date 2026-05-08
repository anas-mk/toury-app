import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/data/countries.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/services/auth_service.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/theme/brand_typography.dart';
import '../../../../../../core/widgets/user_avatar.dart';
import '../../../../../helper/features/profile/presentation/utils/profile_image_helper.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/profile_cubit.dart';

/// Tourist account & profile screen.
///
/// Mirrors the new RAFIQ profile layout:
///   • TopAppBar with avatar (left), wordmark (centre), explore action (right).
///   • Hero card: large avatar + name + email + 2-up bento stats
///     (Trips count + average rating).
///   • Account / Security / Support sections — each row pulls real data
///     from the backend (cached `UserEntity`).
///   • Sign Out CTA in error red.
///
/// Data flow: `TouristProfileCubit.load()` reads the cached user and fires
/// `/user/bookings` (page=1, pageSize=1 → totalCount) and
/// `/ratings/user/{id}/summary` in parallel. All fields are real — no
/// placeholders.
class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TouristProfileCubit>(
      create: (_) => sl<TouristProfileCubit>()..load(),
      child: const _AccountSettingsView(),
    );
  }
}

class _AccountSettingsView extends StatelessWidget {
  const _AccountSettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandTokens.bgSoft,
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<TouristProfileCubit, TouristProfileState>(
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
              context.read<TouristProfileCubit>().clearMessages();
            } else if (state.successMessage != null) {
              messenger.showSnackBar(SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: BrandTokens.successGreen,
                behavior: SnackBarBehavior.floating,
              ));
              context.read<TouristProfileCubit>().clearMessages();
            }
          },
          builder: (context, state) {
            return RefreshIndicator.adaptive(
              onRefresh: () => context.read<TouristProfileCubit>().load(),
              color: BrandTokens.primaryBlue,
              backgroundColor: Colors.white,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
                children: [
                  _ProfileTopBar(user: state.user),
                  const SizedBox(height: 20),
                  _HeroCard(
                    user: state.user,
                    tripsCount: state.tripsCount,
                    rating: state.ratingSummary?.averageStars,
                    isSaving: state.isSaving,
                  ),
                  const SizedBox(height: 28),
                  _AccountSection(user: state.user),
                  const SizedBox(height: 22),
                  _SecuritySection(user: state.user),
                  const SizedBox(height: 22),
                  _SupportSection(),
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
      await sl<AuthService>().clearAuth();
    } catch (_) {
      // Best-effort logout — we still navigate away regardless.
    }
    UserAvatarController.instance.clear();
    if (!context.mounted) return;
    context.go('/login');
  }
}

// ============================================================================
//  TOP BAR (small avatar + RAFIQ wordmark + explore icon)
// ============================================================================

class _ProfileTopBar extends StatelessWidget {
  final UserEntity? user;
  const _ProfileTopBar({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _AvatarThumb(url: user?.profileImageUrl, initial: _initialOf(user)),
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

class _AvatarThumb extends StatelessWidget {
  final String? url;
  final String initial;
  const _AvatarThumb({required this.url, required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: BrandTokens.primaryGradient,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: _AvatarImage(url: url, initial: initial, fontSize: 14),
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
//  HERO CARD (avatar + name + email + bento stats)
// ============================================================================

class _HeroCard extends StatelessWidget {
  final UserEntity? user;
  final int? tripsCount;
  final double? rating;
  final bool isSaving;

  const _HeroCard({
    required this.user,
    required this.tripsCount,
    required this.rating,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final name = _displayName(user);
    final email = user?.email ?? '—';
    final initial = _initialOf(user);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(28),
        boxShadow: BrandTokens.cardShadow,
      ),
      child: Column(
        children: [
          _BigAvatar(
            url: user?.profileImageUrl,
            initial: initial,
            isSaving: isSaving,
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
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _BentoStat(
                  value: tripsCount?.toString() ?? '—',
                  label: loc.translate('profile_trips').toUpperCase(),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    // Jump into the My Bookings shell branch and ask it
                    // to open the "Past" filter via a query param.
                    context.go('${AppRouter.myBookings}?filter=past');
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _BentoStat(
                  value: rating == null
                      ? '—'
                      : rating!.toStringAsFixed(1),
                  label: loc.translate('profile_rating').toUpperCase(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BigAvatar extends StatelessWidget {
  final String? url;
  final String initial;
  final bool isSaving;

  const _BigAvatar({
    required this.url,
    required this.initial,
    required this.isSaving,
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
              _AvatarImage(url: url, initial: initial, fontSize: 32),
              if (isSaving)
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
        Positioned(
          right: -2,
          bottom: -2,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: isSaving
                  ? null
                  : () => showProfileImagePickerSheet(context),
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
      ],
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

    return ValueListenableBuilder<int>(
      valueListenable: UserAvatarController.instance.cacheBuster,
      builder: (context, bust, _) {
        return Image.network(
          // Cache-buster query param so a freshly-uploaded photo at the
          // same URL replaces the previous bytes immediately.
          bust == 0 ? imageUrl : '$imageUrl?v=$bust',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          key: ValueKey('$imageUrl#$bust'),
          errorBuilder: (_, __, ___) => fallback,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return fallback;
          },
        );
      },
    );
  }
}

class _BentoStat extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _BentoStat({required this.value, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: BrandTokens.bgSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandTokens.borderSoft),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: BrandTokens.heading(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: BrandTokens.primaryBlue,
              height: 1.0,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: BrandTokens.heading(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: BrandTokens.textMuted,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      ),
    );
  }
}

// ============================================================================
//  SECTIONS (Account / Security / Support)
// ============================================================================

class _AccountSection extends StatelessWidget {
  final UserEntity? user;
  const _AccountSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final birth = user?.birthDate;
    final formattedBirth = birth == null
        ? '—'
        : DateFormat('d MMM yyyy').format(birth);

    return _SettingsSection(
      title: loc.translate('account'),
      tiles: [
        _SettingTileData(
          label: loc.translate('name'),
          trailing: _emptyOr(_displayName(user)),
          onTap: () => showEditFieldSheet(
            context,
            field: ProfileEditableField.name,
            initialValue: user?.userName,
          ),
        ),
        _SettingTileData(
          label: loc.translate('phone_number'),
          trailing: _emptyOr(user?.phoneNumber),
          onTap: () => showEditFieldSheet(
            context,
            field: ProfileEditableField.phone,
            initialValue: user?.phoneNumber,
            userCountry: user?.country,
          ),
        ),
        _SettingTileData(
          label: loc.translate('country'),
          trailing: _emptyOr(user?.country),
          onTap: () => showEditFieldSheet(
            context,
            field: ProfileEditableField.country,
            initialValue: user?.country,
          ),
        ),
        _SettingTileData(
          label: loc.translate('gender'),
          trailing: _genderLabel(loc, user?.gender),
          onTap: () => showEditFieldSheet(
            context,
            field: ProfileEditableField.gender,
            initialValue: user?.gender,
          ),
        ),
        _SettingTileData(
          label: loc.translate('birth_date'),
          trailing: formattedBirth,
          onTap: () => showEditFieldSheet(
            context,
            field: ProfileEditableField.birthDate,
            initialValue: birth == null
                ? null
                : DateFormat('d MMM yyyy').format(birth),
            initialDate: birth,
          ),
        ),
      ],
    );
  }

  String _emptyOr(String? v) => (v == null || v.isEmpty) ? '—' : v;

  String _genderLabel(AppLocalizations loc, String? gender) {
    if (gender == null || gender.isEmpty) return '—';
    final lower = gender.toLowerCase();
    if (lower == 'male' || lower == 'm') return loc.translate('male');
    if (lower == 'female' || lower == 'f') return loc.translate('female');
    return gender;
  }
}

class _SecuritySection extends StatelessWidget {
  final UserEntity? user;
  const _SecuritySection({required this.user});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return _SettingsSection(
      title: loc.translate('security'),
      tiles: [
        _SettingTileData(
          label: loc.translate('change_password'),
          onTap: () => _changePassword(context, user),
        ),
      ],
    );
  }

  /// Auto-sends a reset OTP to the cached user's email and pushes the
  /// existing reset-password page (no need to retype the email). Reuses
  /// `POST /Auth/forgot-password` + `POST /Auth/reset-password` from the
  /// unauthenticated flow — same security model.
  Future<void> _changePassword(BuildContext context, UserEntity? user) async {
    HapticFeedback.selectionClick();
    final loc = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final email = user?.email;
    if (email == null || email.isEmpty) {
      messenger.showSnackBar(SnackBar(
        content: Text(loc.translate('something_went_wrong')),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final authCubit = sl<AuthCubit>();
    final loadingDialog = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: BrandTokens.primaryBlue),
      ),
    );

    StreamSubscription<AuthState>? sub;
    var resolved = false;
    sub = authCubit.stream.listen((state) {
      if (resolved) return;
      if (state is AuthForgotPasswordSent) {
        resolved = true;
        sub?.cancel();
        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        context.push(
          '${AppRouter.login}/${AppRouter.forgotPassword}/${AppRouter.resetPassword}',
          extra: state.email,
        );
      } else if (state is AuthError) {
        resolved = true;
        sub?.cancel();
        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        messenger.showSnackBar(SnackBar(
          content: Text(state.message),
          backgroundColor: BrandTokens.dangerSos,
          behavior: SnackBarBehavior.floating,
        ));
      }
    });

    await authCubit.forgotPassword(email);
    await loadingDialog;
  }
}

class _SupportSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return _SettingsSection(
      title: loc.translate('support'),
      tiles: [
        _SettingTileData(
          label: loc.translate('help'),
          onTap: () => _comingSoon(context),
        ),
        _SettingTileData(
          label: loc.translate('rate_the_app'),
          onTap: () => _comingSoon(context),
        ),
        _SettingTileData(
          label: loc.translate('about_rafiq'),
          onTap: () => _comingSoon(context),
        ),
      ],
    );
  }
}

// ============================================================================
//  REUSABLE SECTION SHELL
// ============================================================================

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingTileData> tiles;

  const _SettingsSection({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: BrandTokens.heading(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: BrandTokens.textMuted,
              letterSpacing: 1.4,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: BrandTokens.surfaceWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: BrandTokens.cardShadow,
            border: Border.all(color: BrandTokens.borderSoft),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                _SettingTile(data: tiles[i]),
                if (i != tiles.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                    color: BrandTokens.borderSoft,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingTileData {
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  const _SettingTileData({
    required this.label,
    this.trailing,
    required this.onTap,
  });
}

class _SettingTile extends StatelessWidget {
  final _SettingTileData data;
  const _SettingTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  data.label,
                  style: BrandTypography.body(
                    weight: FontWeight.w500,
                    color: BrandTokens.textPrimary,
                  ),
                ),
              ),
              if (data.trailing != null) ...[
                Flexible(
                  child: Text(
                    data.trailing!,
                    textAlign: TextAlign.end,
                    style: BrandTypography.caption(
                      color: BrandTokens.textMuted,
                      weight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                color: BrandTokens.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
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
//  SHARED HELPERS
// ============================================================================

void _comingSoon(BuildContext context) {
  HapticFeedback.selectionClick();
  final loc = AppLocalizations.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(loc.translate('feature_coming_soon')),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

String _displayName(UserEntity? user) {
  final name = user?.userName;
  if (name != null && name.trim().isNotEmpty) return name.trim();
  final email = user?.email;
  if (email != null && email.contains('@')) return email.split('@').first;
  return 'Traveler';
}

String _initialOf(UserEntity? user) {
  final name = _displayName(user);
  if (name.isEmpty) return 'T';
  return name[0].toUpperCase();
}

// ============================================================================
//  EDIT FIELD SHEET — single-field bottom sheet for Account section tiles
// ============================================================================

enum ProfileEditableField {
  name,
  phone,
  country,
  gender,
  birthDate,
}

Future<void> showEditFieldSheet(
  BuildContext context, {
  required ProfileEditableField field,
  required String? initialValue,
  DateTime? initialDate,
  String? userCountry,
}) {
  final cubit = context.read<TouristProfileCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (sheetContext) {
      return BlocProvider.value(
        value: cubit,
        child: _EditFieldSheet(
          field: field,
          initialValue: initialValue,
          initialDate: initialDate,
          userCountry: userCountry,
        ),
      );
    },
  );
}

class _EditFieldSheet extends StatefulWidget {
  final ProfileEditableField field;
  final String? initialValue;
  final DateTime? initialDate;
  final String? userCountry;

  const _EditFieldSheet({
    required this.field,
    required this.initialValue,
    required this.initialDate,
    required this.userCountry,
  });

  @override
  State<_EditFieldSheet> createState() => _EditFieldSheetState();
}

class _EditFieldSheetState extends State<_EditFieldSheet> {
  late final TextEditingController _controller;
  String? _genderValue;
  DateTime? _birthDateValue;
  String? _validationError;

  // Phone-only state.
  Country? _phoneCountry;
  late TextEditingController _phoneNationalController;
  late String _initialDial;
  late String _initialNational;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    if (widget.field == ProfileEditableField.gender) {
      _genderValue = _normalizeGender(widget.initialValue);
    }
    if (widget.field == ProfileEditableField.birthDate) {
      _birthDateValue = widget.initialDate;
    }

    // Split the saved phone number ("+201234567890") into country dial
    // code + national digits so the picker starts on the right country.
    final parsed = _parsePhone(widget.initialValue, widget.userCountry);
    _phoneCountry = parsed.country;
    _initialDial = parsed.country?.dialCode ?? '';
    _initialNational = parsed.national;
    _phoneNationalController = TextEditingController(text: parsed.national);

    // Listen to changes so the Save button enables/disables live.
    _controller.addListener(() => setState(() {}));
    _phoneNationalController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _phoneNationalController.dispose();
    super.dispose();
  }

  String? _normalizeGender(String? raw) {
    if (raw == null) return null;
    final lower = raw.toLowerCase();
    if (lower == 'male' || lower == 'm') return 'Male';
    if (lower == 'female' || lower == 'f') return 'Female';
    if (lower.isEmpty) return null;
    return raw;
  }

  /// Best-effort split of an E.164-ish phone string into country + the
  /// national subscriber digits. Falls back to the user's saved country
  /// when the stored value has no leading "+".
  _ParsedPhone _parsePhone(String? raw, String? country) {
    if (raw == null || raw.trim().isEmpty) {
      final fallback =
          Countries.findByName(country) ?? Countries.findByCode('EG');
      return _ParsedPhone(country: fallback, national: '');
    }
    final cleaned = raw.replaceAll(RegExp(r'[\s\-\(\)]+'), '');
    if (cleaned.startsWith('+')) {
      // Try the longest matching dial code (e.g. "+1876" before "+1").
      final candidates = Countries.all.toList()
        ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));
      for (final c in candidates) {
        if (cleaned.startsWith(c.dialCode)) {
          return _ParsedPhone(
            country: c,
            national: cleaned.substring(c.dialCode.length),
          );
        }
      }
    }
    final fallback =
        Countries.findByName(country) ?? Countries.findByCode('EG');
    return _ParsedPhone(country: fallback, national: cleaned);
  }

  String _titleFor(AppLocalizations loc) {
    switch (widget.field) {
      case ProfileEditableField.name:
        return loc.translate('name');
      case ProfileEditableField.phone:
        return loc.translate('phone_number');
      case ProfileEditableField.country:
        return loc.translate('country');
      case ProfileEditableField.gender:
        return loc.translate('gender');
      case ProfileEditableField.birthDate:
        return loc.translate('birth_date');
    }
  }

  Future<void> _pickBirthDate() async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final initial = _birthDateValue ?? DateTime(now.year - 25);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 13),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: BrandTokens.primaryBlue,
              onPrimary: Colors.white,
              onSurface: BrandTokens.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _birthDateValue = picked);
    }
  }

  Future<void> _pickCountryForField() async {
    HapticFeedback.selectionClick();
    final picked = await _showCountryPicker(
      context,
      initial: Countries.findByName(_controller.text) ??
          Countries.findByName(widget.initialValue),
      mode: _CountryPickerMode.country,
    );
    if (picked != null) {
      setState(() => _controller.text = picked.name);
    }
  }

  Future<void> _pickPhoneCountry() async {
    HapticFeedback.selectionClick();
    final picked = await _showCountryPicker(
      context,
      initial: _phoneCountry,
      mode: _CountryPickerMode.dial,
    );
    if (picked != null) {
      setState(() => _phoneCountry = picked);
    }
  }

  // ── Validations ──────────────────────────────────────────────────────────

  bool get _isDirty {
    switch (widget.field) {
      case ProfileEditableField.name:
        return _controller.text.trim() !=
            (widget.initialValue ?? '').trim();
      case ProfileEditableField.phone:
        final dial = _phoneCountry?.dialCode ?? '';
        final national =
            _phoneNationalController.text.replaceAll(RegExp(r'\D'), '');
        return dial != _initialDial || national != _initialNational;
      case ProfileEditableField.country:
        return _controller.text.trim() !=
            (widget.initialValue ?? '').trim();
      case ProfileEditableField.gender:
        return _genderValue != _normalizeGender(widget.initialValue);
      case ProfileEditableField.birthDate:
        if (_birthDateValue == null) return false;
        if (widget.initialDate == null) return true;
        return !_isSameDay(_birthDateValue!, widget.initialDate!);
    }
  }

  /// Returns a localized error string when the current input is invalid,
  /// or `null` when the value is acceptable.
  String? _validate(AppLocalizations loc) {
    switch (widget.field) {
      case ProfileEditableField.name:
        final v = _controller.text.trim();
        if (v.isEmpty) return loc.translate('field_required');
        if (v.length < 2) return loc.translate('validation_name_too_short');
        if (v.length > 60) return loc.translate('validation_name_too_long');
        if (!RegExp(r"^[A-Za-z\u0600-\u06FF\s\.\-']+$").hasMatch(v)) {
          return loc.translate('validation_name_invalid');
        }
        return null;
      case ProfileEditableField.phone:
        if (_phoneCountry == null) {
          return loc.translate('validation_phone_country_required');
        }
        final national =
            _phoneNationalController.text.replaceAll(RegExp(r'\D'), '');
        if (national.isEmpty) return loc.translate('field_required');
        if (national.length < 5 || national.length > 15) {
          return loc.translate('validation_phone_length');
        }
        return null;
      case ProfileEditableField.country:
        final v = _controller.text.trim();
        if (v.isEmpty) return loc.translate('field_required');
        if (Countries.findByName(v) == null) {
          return loc.translate('validation_country_invalid');
        }
        return null;
      case ProfileEditableField.gender:
        if (_genderValue == null) return loc.translate('select_gender');
        return null;
      case ProfileEditableField.birthDate:
        if (_birthDateValue == null) {
          return loc.translate('select_birth_date');
        }
        return null;
    }
  }

  bool get _canSave {
    final loc = AppLocalizations.of(context);
    return _isDirty && _validate(loc) == null;
  }

  void _save() {
    HapticFeedback.lightImpact();
    final loc = AppLocalizations.of(context);
    final err = _validate(loc);
    if (err != null) {
      setState(() => _validationError = err);
      return;
    }
    if (!_isDirty) {
      Navigator.of(context).pop();
      return;
    }

    final cubit = context.read<TouristProfileCubit>();

    switch (widget.field) {
      case ProfileEditableField.name:
        cubit.updateField(
          userName: _controller.text.trim(),
          successLabel: loc.translate('profile_update_success'),
        );
        break;
      case ProfileEditableField.phone:
        final dial = _phoneCountry!.dialCode;
        final national =
            _phoneNationalController.text.replaceAll(RegExp(r'\D'), '');
        cubit.updateField(
          phoneNumber: '$dial$national',
          successLabel: loc.translate('profile_update_success'),
        );
        break;
      case ProfileEditableField.country:
        cubit.updateField(
          country: _controller.text.trim(),
          successLabel: loc.translate('profile_update_success'),
        );
        break;
      case ProfileEditableField.gender:
        cubit.updateField(
          gender: _genderValue,
          successLabel: loc.translate('profile_update_success'),
        );
        break;
      case ProfileEditableField.birthDate:
        cubit.updateField(
          birthDate: _birthDateValue,
          successLabel: loc.translate('profile_update_success'),
        );
        break;
    }
    Navigator.of(context).pop();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
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
                _titleFor(loc),
                style: BrandTokens.heading(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: BrandTokens.primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
              _buildEditor(loc),
              if (_validationError != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: BrandTokens.dangerSos,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: BrandTypography.caption(
                          color: BrandTokens.dangerSos,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: BrandTokens.borderSoft),
                        foregroundColor: BrandTokens.textSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(loc.translate('cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child:
                        BlocBuilder<TouristProfileCubit, TouristProfileState>(
                      buildWhen: (a, b) => a.isSaving != b.isSaving,
                      builder: (context, state) {
                        final disabled = state.isSaving || !_canSave;
                        return FilledButton(
                          onPressed: disabled ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: BrandTokens.primaryBlue,
                            disabledBackgroundColor:
                                BrandTokens.primaryBlue.withValues(alpha: 0.35),
                            disabledForegroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: state.isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  loc.translate('save_changes'),
                                  style: BrandTypography.body(
                                    weight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        );
                      },
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

  Widget _buildEditor(AppLocalizations loc) {
    switch (widget.field) {
      case ProfileEditableField.name:
        return _buildTextField(
          textInputAction: TextInputAction.done,
          inputFormatters: [LengthLimitingTextInputFormatter(60)],
        );
      case ProfileEditableField.phone:
        return _buildPhoneEditor(loc);
      case ProfileEditableField.country:
        return _buildCountrySelectorTile(loc);
      case ProfileEditableField.gender:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _GenderOption(
              label: loc.translate('male'),
              value: 'Male',
              groupValue: _genderValue,
              onChanged: (v) => setState(() => _genderValue = v),
            ),
            const SizedBox(height: 8),
            _GenderOption(
              label: loc.translate('female'),
              value: 'Female',
              groupValue: _genderValue,
              onChanged: (v) => setState(() => _genderValue = v),
            ),
          ],
        );
      case ProfileEditableField.birthDate:
        final formatted = _birthDateValue == null
            ? loc.translate('select_birth_date')
            : DateFormat('d MMM yyyy').format(_birthDateValue!);
        return InkWell(
          onTap: _pickBirthDate,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: BrandTokens.bgSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: BrandTokens.borderSoft),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: BrandTokens.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    formatted,
                    style: BrandTypography.body(
                      color: _birthDateValue == null
                          ? BrandTokens.textMuted
                          : BrandTokens.textPrimary,
                      weight: FontWeight.w500,
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
        );
    }
  }

  Widget _buildTextField({
    TextInputType? keyboardType,
    required TextInputAction textInputAction,
    List<TextInputFormatter>? inputFormatters,
    TextEditingController? controller,
    String? hint,
  }) {
    return TextField(
      controller: controller ?? _controller,
      autofocus: true,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onSubmitted: (_) => _canSave ? _save() : null,
      onChanged: (_) {
        if (_validationError != null) {
          setState(() => _validationError = null);
        }
      },
      style: BrandTypography.body(weight: FontWeight.w500),
      decoration: InputDecoration(
        filled: true,
        fillColor: BrandTokens.bgSoft,
        hintText: hint,
        hintStyle: BrandTypography.body(color: BrandTokens.textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BrandTokens.borderSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BrandTokens.borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: BrandTokens.primaryBlue,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ── Phone editor: country code dropdown + national number field ──────────

  Widget _buildPhoneEditor(AppLocalizations loc) {
    final country = _phoneCountry;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Material(
          color: BrandTokens.bgSoft,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: _pickPhoneCountry,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 18,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: BrandTokens.borderSoft),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    country?.flag ?? '🌐',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    country?.dialCode ?? '+',
                    style: BrandTypography.body(
                      weight: FontWeight.w700,
                      color: BrandTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.expand_more_rounded,
                    color: BrandTokens.textMuted,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildTextField(
            controller: _phoneNationalController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            hint: loc.translate('phone_national_hint'),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              LengthLimitingTextInputFormatter(15),
            ],
          ),
        ),
      ],
    );
  }

  // ── Country selector tile (used by the Country field) ────────────────────

  Widget _buildCountrySelectorTile(AppLocalizations loc) {
    final picked = Countries.findByName(_controller.text);
    return InkWell(
      onTap: _pickCountryForField,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: BrandTokens.bgSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BrandTokens.borderSoft),
        ),
        child: Row(
          children: [
            Text(
              picked?.flag ?? '🌐',
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                picked?.name ?? loc.translate('country'),
                style: BrandTypography.body(
                  color: picked == null
                      ? BrandTokens.textMuted
                      : BrandTokens.textPrimary,
                  weight: FontWeight.w500,
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
    );
  }
}

class _ParsedPhone {
  final Country? country;
  final String national;
  const _ParsedPhone({required this.country, required this.national});
}

// ============================================================================
//  COUNTRY PICKER (used by phone editor + country editor)
// ============================================================================

enum _CountryPickerMode { country, dial }

Future<Country?> _showCountryPicker(
  BuildContext context, {
  Country? initial,
  required _CountryPickerMode mode,
}) {
  return showModalBottomSheet<Country>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (sheetContext) {
      return _CountryPickerSheet(initial: initial, mode: mode);
    },
  );
}

class _CountryPickerSheet extends StatefulWidget {
  final Country? initial;
  final _CountryPickerMode mode;
  const _CountryPickerSheet({required this.initial, required this.mode});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Country> get _filtered {
    if (_query.isEmpty) return Countries.all;
    final q = _query.toLowerCase().trim();
    return Countries.all.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.code.toLowerCase().contains(q) ||
          c.dialCode.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: media.viewInsets.bottom + 12,
      ),
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
            widget.mode == _CountryPickerMode.dial
                ? loc.translate('select_country_code')
                : loc.translate('select_country'),
            style: BrandTokens.heading(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: BrandTokens.primaryBlue,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            style: BrandTypography.body(weight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: loc.translate('search_country'),
              hintStyle: BrandTypography.body(color: BrandTokens.textMuted),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: BrandTokens.textMuted,
              ),
              filled: true,
              fillColor: BrandTokens.bgSoft,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: BrandTokens.borderSoft),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: BrandTokens.borderSoft),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: BrandTokens.primaryBlue,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      loc.translate('no_results'),
                      style: BrandTypography.body(
                        color: BrandTokens.textMuted,
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final c = _filtered[i];
                      final isSelected = widget.initial?.code == c.code;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(context).pop(c);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  c.flag,
                                  style: const TextStyle(fontSize: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    c.name,
                                    style: BrandTypography.body(
                                      weight: FontWeight.w600,
                                      color: BrandTokens.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  c.dialCode,
                                  style: BrandTypography.caption(
                                    color: BrandTokens.textMuted,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.check_rounded,
                                    color: BrandTokens.primaryBlue,
                                    size: 20,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  final String label;
  final String value;
  final String? groupValue;
  final ValueChanged<String> onChanged;

  const _GenderOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: selected
                ? BrandTokens.primaryBlue.withValues(alpha: 0.06)
                : BrandTokens.bgSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? BrandTokens.primaryBlue
                  : BrandTokens.borderSoft,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? BrandTokens.primaryBlue
                    : BrandTokens.textMuted,
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: BrandTypography.body(
                  weight: FontWeight.w600,
                  color: selected
                      ? BrandTokens.primaryBlue
                      : BrandTokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
//  PROFILE IMAGE PICKER SHEET — camera / gallery
// ============================================================================

Future<void> showProfileImagePickerSheet(BuildContext context) {
  final cubit = context.read<TouristProfileCubit>();
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
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context);
    final cubit = context.read<TouristProfileCubit>();

    File? file;
    try {
      file = await ProfileImageHelper.pickAndValidateImage(source);
    } on FormatException catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(e.message),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    } catch (_) {
      messenger.showSnackBar(SnackBar(
        content: Text(loc.translate('something_went_wrong')),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    if (!context.mounted) return;
    Navigator.of(context).pop();

    if (file == null) return;

    cubit.updateField(
      profileImage: file,
      successLabel: loc.translate('profile_update_success'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
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
              loc.translate('change_profile_photo'),
              style: BrandTokens.heading(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: BrandTokens.primaryBlue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              loc.translate('change_profile_photo_subtitle'),
              style: BrandTypography.caption(color: BrandTokens.textMuted),
            ),
            const SizedBox(height: 20),
            _PickerOptionRow(
              icon: Icons.photo_camera_rounded,
              label: loc.translate('take_photo'),
              onTap: () => _pick(context, ImageSource.camera),
            ),
            const SizedBox(height: 10),
            _PickerOptionRow(
              icon: Icons.photo_library_rounded,
              label: loc.translate('choose_from_gallery'),
              onTap: () => _pick(context, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: BrandTokens.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(loc.translate('cancel')),
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
