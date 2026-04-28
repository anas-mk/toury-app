import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/services/auth_service.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/theme/brand_typography.dart';
import '../../../../../../core/utils/jwt_payload.dart';

/// Phase 2 redesign — Account & Settings (light polish).
///
/// The brief explicitly asks for "light polish only" here. We keep the
/// placeholder `onTap: () {}` tiles in place (those screens don't exist
/// yet) and only restyle the visual layer:
///   • Brand-tinted avatar with initials (no fake "Ahmed User" string).
///   • Soft surface tiles with proper trailing chevrons.
///   • RAFIQ palette via `BrandTokens` and `BrandTypography`.
class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final identity = _resolveIdentity();

    return Scaffold(
      backgroundColor: BrandTokens.bgSoft,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _Header(title: loc.translate('account')),
            const SizedBox(height: 16),
            _ProfileCard(
              name: identity.displayName,
              email: identity.email,
              initial: identity.initial,
            ),
            const SizedBox(height: 22),
            _SectionLabel('PREFERENCES'),
            const SizedBox(height: 8),
            _SettingsGroup(
              tiles: [
                _SettingTileData(
                  icon: Icons.person_outline_rounded,
                  title: 'Edit profile',
                  enabled: false,
                ),
                _SettingTileData(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  enabled: false,
                ),
                _SettingTileData(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  enabled: false,
                ),
              ],
            ),
            const SizedBox(height: 22),
            _SectionLabel('SUPPORT'),
            const SizedBox(height: 8),
            _SettingsGroup(
              tiles: [
                _SettingTileData(
                  icon: Icons.security_rounded,
                  title: 'Privacy & security',
                  enabled: false,
                ),
                _SettingTileData(
                  icon: Icons.help_outline_rounded,
                  title: 'Help center',
                  enabled: false,
                ),
                _SettingTileData(
                  icon: Icons.info_outline_rounded,
                  title: 'About RAFIQ',
                  enabled: false,
                ),
              ],
            ),
            const SizedBox(height: 22),
            _LogoutTile(
              onLogout: () => _confirmLogout(context),
              label: loc.translate('logout'),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'RAFIQ - Your Way, Your Tour.',
                style: BrandTypography.caption(
                  color: BrandTokens.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static _Identity _resolveIdentity() {
    try {
      final token = sl<AuthService>().getToken();
      final payload = JwtPayload.read(token);
      final name = JwtPayload.firstName(token);
      String? email;
      if (payload != null) {
        final raw = payload['email'];
        if (raw is String && raw.contains('@')) email = raw;
      }
      final initial = (name != null && name.isNotEmpty) ? name[0] : 'T';
      return _Identity(
        displayName: (name != null && name.isNotEmpty)
            ? name[0].toUpperCase() + name.substring(1)
            : 'Traveler',
        email: email ?? 'Signed in',
        initial: initial.toUpperCase(),
      );
    } catch (_) {
      return const _Identity(
        displayName: 'Traveler',
        email: 'Signed in',
        initial: 'T',
      );
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    HapticFeedback.lightImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text(
            'You will be signed out of this device. Your active trips and SOS sessions stay safe on the server.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: BrandTokens.dangerSos,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await sl<AuthService>().clearAuth();
    } catch (_) {
      // Best-effort logout; we still navigate away regardless.
    }
    if (!context.mounted) return;
    context.go('/login');
  }
}

class _Identity {
  final String displayName;
  final String email;
  final String initial;
  const _Identity({
    required this.displayName,
    required this.email,
    required this.initial,
  });
}

// ============================================================================
//  HEADER
// ============================================================================

class _Header extends StatelessWidget {
  final String title;
  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(title, style: BrandTypography.headline()),
    );
  }
}

// ============================================================================
//  PROFILE CARD
// ============================================================================

class _ProfileCard extends StatelessWidget {
  final String name;
  final String email;
  final String initial;

  const _ProfileCard({
    required this.name,
    required this.email,
    required this.initial,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: BrandTokens.cardShadow,
        border: Border.all(
          color: BrandTokens.borderTinted.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: BrandTokens.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: BrandTokens.glowBlue,
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              initial,
              style: BrandTokens.heading(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: BrandTypography.title()),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: BrandTypography.caption(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
//  SECTION + GROUP
// ============================================================================

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(label, style: BrandTypography.overline()),
    );
  }
}

class _SettingTileData {
  final IconData icon;
  final String title;
  final bool enabled;
  const _SettingTileData({
    required this.icon,
    required this.title,
    this.enabled = true,
  });
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingTileData> tiles;
  const _SettingsGroup({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: BrandTokens.cardShadow,
      ),
      child: Column(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            _SettingTile(data: tiles[i]),
            if (i != tiles.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: BrandTokens.borderSoft,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final _SettingTileData data;
  const _SettingTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final disabledOpacity = data.enabled ? 1.0 : 0.55;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: data.enabled
            ? () {
                HapticFeedback.selectionClick();
              }
            : null,
        borderRadius: BorderRadius.circular(20),
        child: Opacity(
          opacity: disabledOpacity,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: BrandTokens.primaryBlue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    data.icon,
                    color: BrandTokens.primaryBlue,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data.title,
                    style: BrandTypography.body(weight: FontWeight.w600),
                  ),
                ),
                if (!data.enabled)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: BrandTokens.bgSoft,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: BrandTokens.borderSoft),
                    ),
                    child: Text(
                      'Soon',
                      style: BrandTypography.overline(
                        color: BrandTokens.textMuted,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: BrandTokens.textMuted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
//  LOGOUT
// ============================================================================

class _LogoutTile extends StatelessWidget {
  final VoidCallback onLogout;
  final String label;
  const _LogoutTile({required this.onLogout, required this.label});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onLogout,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: BrandTokens.surfaceWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: BrandTokens.dangerSos.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: BrandTokens.dangerSos.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: BrandTokens.dangerSos,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: BrandTypography.body(
                    weight: FontWeight.w700,
                    color: BrandTokens.dangerSos,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: BrandTokens.dangerSos,
              ),
            ],
          ),
        ),
      ),
    );
  }
}