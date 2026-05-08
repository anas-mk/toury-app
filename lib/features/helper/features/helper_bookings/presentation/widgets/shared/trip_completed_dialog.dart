// Modern celebratory "Trip Completed" dialog used by the active-booking page
// and the booking-details page. The dialog is non-dismissible — the caller
// controls navigation via [onPrimary] and [onSecondary] which run *after*
// the dialog is popped.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_dimens.dart';
import '../../../../../../../core/utils/currency_format.dart';

Future<void> showTripCompletedDialog(
  BuildContext context, {
  required double earnings,
  String title = 'Trip Completed!',
  String primaryLabel = 'Done',
  IconData primaryIcon = Icons.check_rounded,
  String? secondaryLabel,
  String? subtitle,
  VoidCallback? onPrimary,
  VoidCallback? onSecondary,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Trip completed',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      final scale = Tween<double>(begin: 0.9, end: 1).animate(
        CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
      );
      final fade = Tween<double>(begin: 0, end: 1).animate(anim);
      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(
          scale: scale,
          child: _TripCompletedContent(
            earnings: earnings,
            title: title,
            primaryLabel: primaryLabel,
            primaryIcon: primaryIcon,
            subtitle: subtitle,
            secondaryLabel: secondaryLabel,
            onPrimary: onPrimary,
            onSecondary: onSecondary,
          ),
        ),
      );
    },
  );
}

class _TripCompletedContent extends StatelessWidget {
  final double earnings;
  final String title;
  final String primaryLabel;
  final IconData primaryIcon;
  final String? subtitle;
  final String? secondaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;

  const _TripCompletedContent({
    required this.earnings,
    required this.title,
    required this.primaryLabel,
    required this.primaryIcon,
    this.subtitle,
    this.secondaryLabel,
    this.onPrimary,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: mediaQuery.padding.bottom + AppSpacing.xl,
        ),
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              decoration: BoxDecoration(
                color: palette.surfaceElevated,
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CelebrationHeader(palette: palette),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xxl,
                        AppSpacing.lg,
                        AppSpacing.xxl,
                        AppSpacing.xxl,
                      ),
                      child: Column(
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: palette.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'You earned',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: palette.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ShaderMask(
                            shaderCallback: (rect) => LinearGradient(
                              colors: [
                                palette.success,
                                Color.lerp(
                                  palette.success,
                                  Colors.black,
                                  0.15,
                                )!,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(rect),
                            child: Text(
                              Money.egp(earnings),
                              style: theme.textTheme.displaySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 38,
                                letterSpacing: -0.6,
                              ),
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              subtitle!,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xxl),
                          SizedBox(
                            width: double.infinity,
                            height: AppSize.buttonLg,
                            child: ElevatedButton.icon(
                              icon: Icon(primaryIcon, color: Colors.white),
                              label: Text(
                                primaryLabel,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: palette.primary,
                                elevation: 0,
                                shadowColor: palette.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.lg),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                onPrimary?.call();
                              },
                            ),
                          ),
                          if (secondaryLabel != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                onSecondary?.call();
                              },
                              child: Text(
                                secondaryLabel!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: palette.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
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

class _CelebrationHeader extends StatefulWidget {
  final AppColors palette;
  const _CelebrationHeader({required this.palette});

  @override
  State<_CelebrationHeader> createState() => _CelebrationHeaderState();
}

class _CelebrationHeaderState extends State<_CelebrationHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return SizedBox(
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  palette.success,
                  Color.lerp(palette.success, palette.primary, 0.55)!,
                ],
              ),
            ),
          ),
          // Floating decorative orbs.
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              return Stack(
                children: [
                  Positioned(
                    top: 18 + 4 * math.sin(_ctrl.value * 2 * math.pi),
                    left: 30,
                    child: _orb(48, 0.18),
                  ),
                  Positioned(
                    top: 80,
                    right: 26 + 4 * math.cos(_ctrl.value * 2 * math.pi),
                    child: _orb(28, 0.20),
                  ),
                  Positioned(
                    bottom: 14,
                    left: 70,
                    child: _orb(20, 0.25),
                  ),
                  Positioned(
                    bottom: 28,
                    right: 60,
                    child: _orb(36, 0.16),
                  ),
                ],
              );
            },
          ),
          // Big check medallion.
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 48,
                  color: palette.success,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orb(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: alpha),
          shape: BoxShape.circle,
        ),
      );
}
