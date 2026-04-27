import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/di/injection_container.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/utils/responsive.dart';
import '../../../../../../../core/widgets/app_network_image.dart';
import '../../../../../../../core/widgets/brand/mesh_gradient.dart';
import '../../../domain/entities/helper_booking_profile.dart';
import '../../../domain/entities/helper_search_result.dart';
import '../../cubits/helper_booking_profile_cubit.dart';
import '../../cubits/instant_booking_cubit.dart';
import '../../widgets/instant/empty_error_state.dart';
import '../../widgets/instant/skeleton.dart';
import 'location_pick_result.dart';

/// Step 5 — full helper profile page (Pass #5 redesign).
///
/// Layout pillars:
///   • Mesh-gradient hero with frosted glass avatar plate
///   • 3-up "trust strip" (trips, response, acceptance)
///   • Section cards on a soft surface, never plain dividers
///   • Sticky frosted CTA dock with `EGP …` + "Request now"
class HelperBookingProfilePage extends StatelessWidget {
  final InstantBookingCubit cubit;
  final HelperSearchResult helper;
  final LocationPickResult pickup;
  final LocationPickResult destination;
  final int travelers;
  final int durationInMinutes;
  final String? languageCode;
  final bool requiresCar;
  final String? notes;

  const HelperBookingProfilePage({
    super.key,
    required this.cubit,
    required this.helper,
    required this.pickup,
    required this.destination,
    required this.travelers,
    required this.durationInMinutes,
    required this.languageCode,
    required this.requiresCar,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: cubit),
        BlocProvider(
          create: (_) =>
              sl<HelperBookingProfileCubit>()..load(helper.helperId),
        ),
      ],
      child: _ProfileView(
        helper: helper,
        pickup: pickup,
        destination: destination,
        travelers: travelers,
        durationInMinutes: durationInMinutes,
        languageCode: languageCode,
        requiresCar: requiresCar,
        notes: notes,
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  final HelperSearchResult helper;
  final LocationPickResult pickup;
  final LocationPickResult destination;
  final int travelers;
  final int durationInMinutes;
  final String? languageCode;
  final bool requiresCar;
  final String? notes;

  const _ProfileView({
    required this.helper,
    required this.pickup,
    required this.destination,
    required this.travelers,
    required this.durationInMinutes,
    required this.languageCode,
    required this.requiresCar,
    required this.notes,
  });

  void _onRequest(BuildContext context) {
    HapticFeedback.mediumImpact();
    context.push(
      AppRouter.instantBookingReview,
      extra: {
        'cubit': context.read<InstantBookingCubit>(),
        'helper': helper,
        'pickup': pickup,
        'destination': destination,
        'travelers': travelers,
        'durationInMinutes': durationInMinutes,
        'languageCode': languageCode,
        'requiresCar': requiresCar,
        'notes': notes,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return Scaffold(
      backgroundColor: BrandTokens.bgSoft,
      body: Stack(
        children: [
          Positioned.fill(
            child:
                BlocBuilder<HelperBookingProfileCubit, HelperBookingProfileState>(
              builder: (context, state) {
                if (state is HelperBookingProfileLoaded) {
                  return _ProfileBody(profile: state.profile, helper: helper);
                }
                if (state is HelperBookingProfileError) {
                  return ErrorRetryState(
                    message: state.message,
                    onRetry: () => context
                        .read<HelperBookingProfileCubit>()
                        .load(helper.helperId),
                  );
                }
                return const _ProfileSkeleton();
              },
            ),
          ),
          Positioned(
            top: r.viewPadding.top + 6,
            left: r.pagePadding - 8,
            child: const _GlassBackButton(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _CtaDock(
              priceLabel: 'EGP ${helper.estimatedPrice.toStringAsFixed(0)}',
              onRequest: () => _onRequest(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: Colors.white.withValues(alpha: 0.22),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).maybePop();
            },
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//                         STICKY CTA DOCK
// ─────────────────────────────────────────────────────────────────────────────
class _CtaDock extends StatelessWidget {
  final String priceLabel;
  final VoidCallback onRequest;
  const _CtaDock({required this.priceLabel, required this.onRequest});

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: BrandTokens.surfaceWhite.withValues(alpha: 0.92),
              border: Border(
                top: BorderSide(
                  color: BrandTokens.borderSoft.withValues(alpha: 0.8),
                ),
              ),
              boxShadow: const [
                BoxShadow(
                  color: BrandTokens.shadowSoft,
                  blurRadius: 32,
                  offset: Offset(0, -8),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  r.pagePadding,
                  r.gap,
                  r.pagePadding,
                  r.gap,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Estimated total',
                            style: BrandTokens.body(
                              fontSize: r.fontSmall,
                              color: BrandTokens.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            priceLabel,
                            style: BrandTokens.numeric(
                              fontSize: r.pick(
                                  compact: 22.0, phone: 24.0, tablet: 28.0),
                              fontWeight: FontWeight.w800,
                              color: BrandTokens.primaryBlue,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: r.gapSM),
                    Expanded(
                      flex: 5,
                      child: _PrimaryCta(
                        label: 'Request now',
                        icon: Icons.send_rounded,
                        onTap: onRequest,
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

class _PrimaryCta extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PrimaryCta({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          height: r.ctaHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                BrandTokens.successGreen,
                BrandTokens.primaryBlue,
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: BrandTokens.glowBlue,
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: r.fontTitle),
                SizedBox(width: r.gapSM),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BrandTokens.heading(
                      fontSize: r.fontBody + 1,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//                         BODY
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileBody extends StatelessWidget {
  final HelperBookingProfile profile;
  final HelperSearchResult helper;
  const _ProfileBody({required this.profile, required this.helper});

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _Hero(profile: profile, helper: helper),
        ),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: r.contentMaxWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: r.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.translate(
                      offset: Offset(0,
                          -r.pick(compact: 28.0, phone: 34.0, tablet: 40.0)),
                      child: _TrustStrip(profile: profile),
                    ),
                    SizedBox(height: r.gapSM),
                    if ((profile.bio ?? '').isNotEmpty) ...[
                      _SectionHeader(label: 'About'),
                      SizedBox(height: r.gapSM),
                      _GlassCard(
                        child: Text(
                          profile.bio!,
                          style: BrandTokens.body(
                            fontSize: r.fontBody,
                            height: 1.55,
                            color: BrandTokens.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(height: r.gap),
                    ],
                    if (profile.languages.isNotEmpty) ...[
                      _SectionHeader(label: 'Languages'),
                      SizedBox(height: r.gapSM),
                      _GlassCard(
                        child: Wrap(
                          spacing: r.gapSM,
                          runSpacing: r.gapSM,
                          children: [
                            for (final l in profile.languages)
                              _LangPill(language: l),
                          ],
                        ),
                      ),
                      SizedBox(height: r.gap),
                    ],
                    if (profile.hasCar && profile.car != null) ...[
                      _SectionHeader(label: 'Vehicle'),
                      SizedBox(height: r.gapSM),
                      _CarCard(car: profile.car!),
                      SizedBox(height: r.gap),
                    ],
                    if (profile.serviceAreas.isNotEmpty) ...[
                      _SectionHeader(label: 'Service areas'),
                      SizedBox(height: r.gapSM),
                      _GlassCard(
                        child: Wrap(
                          spacing: r.gapSM,
                          runSpacing: r.gapSM,
                          children: [
                            for (final a in profile.serviceAreas)
                              _AreaPill(area: a),
                          ],
                        ),
                      ),
                      SizedBox(height: r.gap),
                    ],
                    if (profile.certificates.isNotEmpty) ...[
                      _SectionHeader(label: 'Certificates'),
                      SizedBox(height: r.gapSM),
                      _GlassCard(
                        child: Wrap(
                          spacing: r.gapSM,
                          runSpacing: r.gapSM,
                          children: [
                            for (final c in profile.certificates)
                              _CertPill(label: c),
                          ],
                        ),
                      ),
                      SizedBox(height: r.gap),
                    ],
                    if (helper.suitabilityReasons.isNotEmpty) ...[
                      _SectionHeader(
                        label: 'Why ${profile.fullName.split(' ').first}?',
                      ),
                      SizedBox(height: r.gapSM),
                      _GlassCard(
                        padding: EdgeInsets.symmetric(
                          horizontal: r.gap,
                          vertical: r.gapSM + 2,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final reason in helper.suitabilityReasons)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 6),
                                child: _ReasonRow(text: reason),
                              ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(
                        height: r.pick(
                            compact: 120.0, phone: 140.0, tablet: 160.0)),
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

// ─────────────────────────────────────────────────────────────────────────────
//                         HERO
// ─────────────────────────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  final HelperBookingProfile profile;
  final HelperSearchResult helper;
  const _Hero({required this.profile, required this.helper});

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final topPad = r.viewPadding.top +
        r.pick(compact: 50.0, phone: 56.0, tablet: 64.0);
    final heroHeight = r.pick(compact: 280.0, phone: 310.0, tablet: 340.0);

    return SizedBox(
      height: heroHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipPath(
              clipper: _HeroBlobClipper(),
              child: const MeshGradientBackground(),
            ),
          ),
          // Soft top vignette so the back button stays legible.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topPad + 16,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: topPad,
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AvatarPlate(profile: profile, size: r.heroAvatar),
                SizedBox(height: r.gapSM + 2),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: r.pagePadding),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          profile.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: BrandTokens.heading(
                            fontSize: r.pick(
                                compact: 20.0, phone: 22.0, tablet: 26.0),
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.verified_rounded,
                          color: Colors.white, size: r.fontTitle),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                _RatingPill(
                  rating: profile.rating,
                  count: profile.ratingCount,
                ),
                SizedBox(height: r.gapSM),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: r.pagePadding),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: [
                      if ((profile.gender ?? '').isNotEmpty)
                        _HeroChip(label: profile.gender!),
                      if (profile.age != null)
                        _HeroChip(label: '${profile.age} y/o'),
                      _HeroChip(
                        label: '${profile.experienceYears}y exp',
                        icon: Icons.workspace_premium_rounded,
                      ),
                    ],
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

class _HeroBlobClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.lineTo(0, size.height - 36);
    p.quadraticBezierTo(
      size.width * 0.25,
      size.height - 8,
      size.width * 0.55,
      size.height - 22,
    );
    p.quadraticBezierTo(
      size.width * 0.85,
      size.height - 38,
      size.width,
      size.height - 12,
    );
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _AvatarPlate extends StatelessWidget {
  final HelperBookingProfile profile;
  final double size;
  const _AvatarPlate({required this.profile, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFFFE7A6)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(3),
        child: AppNetworkImage(
          imageUrl: profile.profileImageUrl,
          width: size,
          height: size,
          borderRadius: size / 2,
        ),
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  final double rating;
  final int count;
  const _RatingPill({required this.rating, required this.count});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded,
                  color: Color(0xFFFFD56B), size: 18),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: BrandTokens.numeric(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '($count)',
                style: BrandTokens.body(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  const _HeroChip({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: BrandTokens.body(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//                         TRUST STRIP
// ─────────────────────────────────────────────────────────────────────────────
class _TrustStrip extends StatelessWidget {
  final HelperBookingProfile profile;
  const _TrustStrip({required this.profile});

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final acc = profile.acceptanceRate ?? 0;
    final accColor = acc >= 0.8
        ? BrandTokens.successGreen
        : acc >= 0.5
            ? BrandTokens.warningAmber
            : BrandTokens.dangerRed;

    return _GlassCard(
      padding: EdgeInsets.symmetric(
        horizontal: r.gapSM + 2,
        vertical: r.gap,
      ),
      child: Row(
        children: [
          Expanded(
            child: _TrustItem(
              icon: Icons.task_alt_rounded,
              label: 'Trips',
              value: profile.completedTrips.toString(),
              color: BrandTokens.primaryBlue,
            ),
          ),
          _Divider(),
          Expanded(
            child: _TrustItem(
              icon: Icons.bolt_rounded,
              label: 'Response',
              value: _responseLabel(profile.averageResponseTimeSeconds),
              color: BrandTokens.accentAmber,
            ),
          ),
          _Divider(),
          Expanded(
            child: _TrustItem(
              icon: Icons.verified_user_rounded,
              label: 'Acceptance',
              value: '${(acc * 100).round()}%',
              color: accColor,
            ),
          ),
        ],
      ),
    );
  }

  static String _responseLabel(int? seconds) {
    if (seconds == null) return '\u2014';
    if (seconds < 60) return '${seconds}s';
    return '${seconds ~/ 60}m';
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: BrandTokens.borderSoft,
    );
  }
}

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TrustItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon,
              color: color,
              size: r.pick(compact: 14.0, phone: 16.0, tablet: 18.0)),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: BrandTokens.numeric(
            fontSize: r.pick(compact: 15.0, phone: 17.0, tablet: 19.0),
            fontWeight: FontWeight.w800,
            color: BrandTokens.textPrimary,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: BrandTokens.body(
            fontSize: r.fontSmall,
            color: BrandTokens.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//                         SECTION HEADER + GLASS CARD
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  BrandTokens.successGreen,
                  BrandTokens.primaryBlue,
                ],
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BrandTokens.heading(
                fontSize: r.fontTitle,
                fontWeight: FontWeight.w800,
                color: BrandTokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const _GlassCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return Container(
      padding: padding ?? EdgeInsets.all(r.gap),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: BrandTokens.borderSoft.withValues(alpha: 0.7),
        ),
        boxShadow: BrandTokens.cardShadow,
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//                         PILLS
// ─────────────────────────────────────────────────────────────────────────────
class _LangPill extends StatelessWidget {
  final HelperLanguage language;
  const _LangPill({required this.language});

  @override
  Widget build(BuildContext context) {
    final hasLevel = (language.level ?? '').isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: BrandTokens.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: BrandTokens.primaryBlue.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            language.isVerified
                ? Icons.verified_rounded
                : Icons.translate_rounded,
            size: 14,
            color: language.isVerified
                ? BrandTokens.successGreen
                : BrandTokens.primaryBlue,
          ),
          const SizedBox(width: 6),
          Text(
            language.languageName,
            style: BrandTokens.body(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: BrandTokens.primaryBlue,
            ),
          ),
          if (hasLevel) ...[
            Text(
              ' \u00b7 ',
              style: BrandTokens.body(
                fontSize: 12,
                color: BrandTokens.primaryBlue.withValues(alpha: 0.55),
              ),
            ),
            Text(
              language.level!,
              style: BrandTokens.body(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: BrandTokens.primaryBlue.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AreaPill extends StatelessWidget {
  final HelperServiceArea area;
  const _AreaPill({required this.area});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      area.city,
      if ((area.areaName ?? '').isNotEmpty) area.areaName!,
    ];
    final label = parts.join(', ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: BrandTokens.bgSoft,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: BrandTokens.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.place_rounded,
              size: 14, color: BrandTokens.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: BrandTokens.body(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: BrandTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CertPill extends StatelessWidget {
  final String label;
  const _CertPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: BrandTokens.accentAmberSoft,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: BrandTokens.accentAmberBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium_rounded,
              size: 14, color: BrandTokens.accentAmberText),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BrandTokens.body(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: BrandTokens.accentAmberText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//                         CAR + REASON
// ─────────────────────────────────────────────────────────────────────────────
class _CarCard extends StatelessWidget {
  final HelperCarInfo car;
  const _CarCard({required this.car});

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final desc = [car.brand, car.model, car.color, car.type]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .join(' \u00b7 ');
    return _GlassCard(
      padding: EdgeInsets.all(r.gap),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: BrandTokens.amberGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: BrandTokens.glowAmber,
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: Colors.white,
            ),
          ),
          SizedBox(width: r.gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  desc.isEmpty ? 'Helper has a vehicle' : desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: BrandTokens.heading(
                    fontSize: r.fontBody + 1,
                    fontWeight: FontWeight.w700,
                    color: BrandTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Personal vehicle included',
                  style: BrandTokens.body(
                    fontSize: r.fontSmall,
                    color: BrandTokens.textSecondary,
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

class _ReasonRow extends StatelessWidget {
  final String text;
  const _ReasonRow({required this.text});

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: BrandTokens.successGreen.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: BrandTokens.successGreen,
            size: 13,
          ),
        ),
        SizedBox(width: r.gapSM),
        Expanded(
          child: Text(
            text,
            style: BrandTokens.body(
              fontSize: r.fontBody,
              color: BrandTokens.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//                         SKELETON
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        r.pagePadding,
        r.viewPadding.top + 80,
        r.pagePadding,
        r.gap,
      ),
      children: [
        Center(
          child: SkeletonBox(
            width: r.heroAvatar,
            height: r.heroAvatar,
            borderRadius: r.heroAvatar / 2,
          ),
        ),
        SizedBox(height: r.gap),
        const Center(child: SkeletonBox(height: 22, width: 180)),
        const SizedBox(height: 8),
        const Center(child: SkeletonBox(height: 14, width: 120)),
        SizedBox(height: r.gapLG),
        const Row(
          children: [
            Expanded(child: SkeletonBox(height: 80, width: double.infinity)),
            SizedBox(width: 8),
            Expanded(child: SkeletonBox(height: 80, width: double.infinity)),
            SizedBox(width: 8),
            Expanded(child: SkeletonBox(height: 80, width: double.infinity)),
          ],
        ),
        SizedBox(height: r.gapLG),
        const SkeletonBox(height: 60, width: double.infinity),
        SizedBox(height: r.gap),
        const SkeletonBox(height: 60, width: double.infinity),
      ],
    );
  }
}
