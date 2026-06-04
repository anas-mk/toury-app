import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/brand_tokens.dart';
import '../../../../core/widgets/app_scaffold.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppScaffold(
      safeAreaBody: true,
      body: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Center(
                child: Image.asset(
                  'assets/logo/logo.png',
                  height: 88,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Text(
                loc.translate('select_role'),
                textAlign: TextAlign.center,
                style: BrandTokens.heading(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                loc.translate('continue_as'),
                textAlign: TextAlign.center,
                style: BrandTokens.body(
                  fontSize: 15,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(flex: 3),
              _RoleOption(
                title: loc.translate('tourist'),
                icon: Icons.explore_outlined,
                iconColor: scheme.primary,
                onTap: () =>
                    context.push(AppRouter.login, extra: 'from_role_selection'),
              ),
              const SizedBox(height: AppSpacing.md),
              _RoleOption(
                title: loc.translate('guide'),
                icon: Icons.badge_outlined,
                iconColor: BrandTokens.accentAmber,
                onTap: () => context.push(
                  AppRouter.helperLogin,
                  extra: 'from_role_selection',
                ),
              ),
              const Spacer(flex: 2),
              Text(
                'By continuing you agree to our Terms & Privacy Policy',
                textAlign: TextAlign.center,
                style: BrandTokens.body(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _RoleOption({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  title,
                  style: BrandTokens.heading(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
