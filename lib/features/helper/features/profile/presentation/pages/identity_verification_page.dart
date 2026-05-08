import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/animations/fade_in_slide.dart';
import '../../domain/entities/helper_profile_entity.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../widgets/documents/documents_checklist.dart';

class IdentityVerificationPage extends StatelessWidget {
  final HelperProfileEntity profile;
  const IdentityVerificationPage({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: palette.scaffold,
      appBar: AppBar(
        leading: const _BackButton(),
        title: Text(
          'Verification',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: palette.scaffold,
      ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          return ListView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              FadeInSlide(
                duration: const Duration(milliseconds: 500),
                child: _VerificationHeroCard(profile: profile),
              ),
              const SizedBox(height: 20),
              FadeInSlide(
                delay: const Duration(milliseconds: 100),
                child: _SectionTitle(
                  title: 'Verification Items',
                  subtitle: 'Status of each required document',
                ),
              ),
              const SizedBox(height: 12),
              FadeInSlide(
                delay: const Duration(milliseconds: 150),
                child: _StatusList(profile: profile),
              ),
              const SizedBox(height: 24),
              FadeInSlide(
                delay: const Duration(milliseconds: 200),
                child: _SectionTitle(
                  title: 'Document Upload',
                  subtitle: 'Upload clear photos of your documents',
                ),
              ),
              const SizedBox(height: 12),
              FadeInSlide(
                delay: const Duration(milliseconds: 250),
                child: const DocumentsChecklist(),
              ),
              const SizedBox(height: 16),
              FadeInSlide(
                delay: const Duration(milliseconds: 300),
                child: const _TipsCard(),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  HERO CARD WITH CIRCULAR PROGRESS
// ──────────────────────────────────────────────────────────────────────────────

class _VerificationHeroCard extends StatelessWidget {
  final HelperProfileEntity profile;
  const _VerificationHeroCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    final approved = profile.isApproved;
    final hasSelfie = profile.selfieImageUrl != null && profile.selfieImageUrl!.isNotEmpty;
    final hasImage = profile.profileImageUrl != null && profile.profileImageUrl!.isNotEmpty;

    int total = 4;
    int done = 0;
    if (approved) done++;
    if (hasSelfie) done++;
    if (hasImage) done++;
    if (profile.car != null) done++;
    final progress = done / total;

    final accent = approved ? palette.success : palette.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.isDark
              ? [
                  accent.withValues(alpha: 0.30),
                  accent.withValues(alpha: 0.16),
                  const Color(0xFF7B61FF).withValues(alpha: 0.16),
                ]
              : [
                  accent.withValues(alpha: 0.95),
                  accent.withValues(alpha: 0.85),
                  const Color(0xFF7B61FF).withValues(alpha: 0.85),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: palette.isDark ? 0.20 : 0.30),
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
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: _CircularProgress(
                  progress: progress,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(progress * 100).round()}%',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                          ),
                        ),
                        Text(
                          '$done / $total',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            approved ? Icons.verified_rounded : Icons.shield_outlined,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            approved ? 'VERIFIED' : 'IN PROGRESS',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      approved ? 'You\'re all set!' : 'Almost there',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 19,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      approved
                          ? 'Your account has been fully verified and is ready for jobs.'
                          : 'Complete the remaining steps to unlock all features.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircularProgress extends StatelessWidget {
  final double progress;
  final Widget child;
  const _CircularProgress({required this.progress, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RingPainter(progress: progress),
      child: child,
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 6.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - stroke) / 2;

    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);

    final start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ──────────────────────────────────────────────────────────────────────────────
//  STATUS LIST
// ──────────────────────────────────────────────────────────────────────────────

class _StatusList extends StatelessWidget {
  final HelperProfileEntity profile;
  const _StatusList({required this.profile});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final items = [
      _StatusItem(
        label: 'National ID',
        description: 'Front & back uploaded',
        isVerified: profile.isApproved,
        icon: Icons.badge_outlined,
      ),
      _StatusItem(
        label: 'Criminal Record',
        description: 'Background clearance',
        isVerified: profile.isApproved,
        icon: Icons.gavel_outlined,
      ),
      _StatusItem(
        label: 'Drug Test',
        description: 'Medical certificate',
        isVerified: profile.isApproved,
        icon: Icons.medical_services_outlined,
      ),
      _StatusItem(
        label: 'Selfie Verification',
        description: 'Live photo match',
        isVerified: profile.selfieImageUrl != null && profile.selfieImageUrl!.isNotEmpty,
        icon: Icons.face_outlined,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border, width: 0.5),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 64),
                child: Divider(height: 1, thickness: 0.5, color: palette.border),
              ),
          ],
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final String description;
  final bool isVerified;
  final IconData icon;

  const _StatusItem({
    required this.label,
    required this.description,
    required this.isVerified,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    final color = isVerified ? palette.success : palette.warning;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: palette.isDark ? 0.22 : 0.16),
                  color.withValues(alpha: palette.isDark ? 0.10 : 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: palette.isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isVerified ? Icons.check_rounded : Icons.schedule_rounded,
                  size: 12,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  isVerified ? 'Verified' : 'Pending',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
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

// ──────────────────────────────────────────────────────────────────────────────
//  HELPERS
// ──────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
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
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: palette.isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: palette.primary.withValues(alpha: 0.20),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.tips_and_updates_rounded, color: palette.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Photo tips for fast approval',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Take photos in good lighting, avoid glare, and make sure all text is clearly readable.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: palette.textSecondary,
                    height: 1.4,
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

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.maybePop(context),
          customBorder: const CircleBorder(),
          child: Container(
            decoration: BoxDecoration(
              color: palette.surface,
              shape: BoxShape.circle,
              border: Border.all(color: palette.border),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: palette.textPrimary,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}
