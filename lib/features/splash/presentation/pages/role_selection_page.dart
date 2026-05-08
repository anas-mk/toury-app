import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/brand_tokens.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/app_scaffold.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final mediaTop = MediaQuery.of(context).padding.top;

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Branded top panel ─────────────────────────────────────
          Container(
            color: BrandTokens.primaryBlue,
            padding: EdgeInsets.fromLTRB(24, mediaTop + 20, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/logo/logo.png',
                  height: 52,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome to TOURY',
                  style: BrandTokens.heading(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'How would you like to continue?',
                  style: BrandTokens.body(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),

          // ── Role cards ────────────────────────────────────────────
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: child,
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    _RoleCard(
                      title: loc.translate('tourist'),
                      subtitle: 'Book rides, schedule tours, track live',
                      icon: Icons.directions_car_rounded,
                      tag: 'PASSENGER',
                      onTap: () => context.push(
                        AppRouter.login,
                        extra: 'from_role_selection',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _RoleCard(
                      title: loc.translate('helper'),
                      subtitle: 'Drive, guide, and earn on every trip',
                      icon: Icons.badge_rounded,
                      tag: 'PARTNER',
                      onTap: () => context.push(
                        AppRouter.helperLogin,
                        extra: 'from_role_selection',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'By continuing you agree to our Terms & Privacy Policy',
                      style: BrandTokens.body(
                        fontSize: 11,
                        color: BrandTokens.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String tag;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tag,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: BrandTokens.borderSoft),
            boxShadow: BrandTokens.cardShadow,
          ),
          child: Row(
            children: [
              // Icon box
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: BrandTokens.primaryBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.title,
                          style: BrandTokens.heading(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: BrandTokens.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: BrandTokens.primaryBlue.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.tag,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: BrandTokens.primaryBlue,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: BrandTokens.body(
                        fontSize: 13,
                        color: BrandTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: BrandTokens.bgSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: BrandTokens.primaryBlue,
                  size: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
