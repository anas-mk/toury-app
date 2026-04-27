import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/di/injection_container.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/widgets/app_network_image.dart';
import '../../../../../../../core/widgets/hero_header.dart';
import '../../../domain/entities/helper_booking_profile.dart';
import '../../../domain/entities/helper_search_result.dart';
import '../../cubits/helper_booking_profile_cubit.dart';
import '../../cubits/instant_booking_cubit.dart';
import '../../widgets/instant/empty_error_state.dart';
import '../../widgets/instant/skeleton.dart';
import 'location_pick_result.dart';

/// Step 5 â€” full helper profile page. Sticky bottom bar shows the
/// estimated price (taken from the search result we already have) and a
/// "Request now" CTA â†’ BookingReviewPage.
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // Stack-based layout instead of `bottomNavigationBar` — the latter
      // was producing weird placements (the action bar landed at the top
      // of the screen) when the body collapsed. With a Stack we control
      // the action-bar position explicitly via Positioned(bottom:0) and
      // the body always fills the screen with `Positioned.fill`.
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
          // Always-reachable back button, regardless of state. Without
          // this the user can be trapped during loading/error states
          // (the in-hero back button only renders in Loaded state).
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            left: 4,
            child: const _OverlayBackButton(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ActionBar(
              priceLabel: 'EGP ${helper.estimatedPrice.toStringAsFixed(0)}',
              onRequest: () => _onRequest(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayBackButton extends StatelessWidget {
  const _OverlayBackButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).maybePop(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
      ),
    );
  }
}

/// Sticky bottom bar with the estimated total on the left and the
/// "Request now" CTA on the right. Layout uses `Expanded` instead of a
/// fixed 180px width so it never overflows on narrow screens.
class _ActionBar extends StatelessWidget {
  final String priceLabel;
  final VoidCallback onRequest;
  const _ActionBar({required this.priceLabel, required this.onRequest});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceLG,
          AppTheme.spaceMD,
          AppTheme.spaceLG,
          AppTheme.spaceMD,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Estimated total',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColor.lightTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    priceLabel,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColor.accentColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              flex: 5,
              child: _GradientCta(
                label: 'Request now',
                icon: Icons.send_rounded,
                onTap: onRequest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final HelperBookingProfile profile;
  final HelperSearchResult helper;
  const _ProfileBody({required this.profile, required this.helper});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          pinned: false,
          delegate: _ProfileHeroDelegate(profile: profile),
        ),
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -36),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceLG,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatsRow(profile: profile),
                  const SizedBox(height: AppTheme.spaceLG),
                  if ((profile.bio ?? '').isNotEmpty) ...[
                    SectionTitle('About'),
                    const SizedBox(height: AppTheme.spaceSM),
                    _SoftCard(
                      child: Text(
                        profile.bio!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(height: 1.45),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceLG),
                  ],
                  if (profile.languages.isNotEmpty) ...[
                    SectionTitle('Languages'),
                    const SizedBox(height: AppTheme.spaceSM),
                    _SoftCard(
                      child: Wrap(
                        spacing: AppTheme.spaceSM,
                        runSpacing: AppTheme.spaceSM,
                        children: [
                          for (final l in profile.languages)
                            _LanguageChip(language: l),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceLG),
                  ],
                  if (profile.hasCar && profile.car != null) ...[
                    SectionTitle('Vehicle'),
                    const SizedBox(height: AppTheme.spaceSM),
                    _CarCard(car: profile.car!),
                    const SizedBox(height: AppTheme.spaceLG),
                  ],
                  if (profile.serviceAreas.isNotEmpty) ...[
                    SectionTitle('Service areas'),
                    const SizedBox(height: AppTheme.spaceSM),
                    _SoftCard(
                      child: Wrap(
                        spacing: AppTheme.spaceSM,
                        runSpacing: AppTheme.spaceSM,
                        children: [
                          for (final a in profile.serviceAreas)
                            _ServiceAreaChip(area: a),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceLG),
                  ],
                  if (profile.certificates.isNotEmpty) ...[
                    SectionTitle('Certificates'),
                    const SizedBox(height: AppTheme.spaceSM),
                    _SoftCard(
                      child: Wrap(
                        spacing: AppTheme.spaceSM,
                        runSpacing: AppTheme.spaceSM,
                        children: [
                          for (final c in profile.certificates)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spaceSM,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColor.warningColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusFull,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.workspace_premium_rounded,
                                    size: 14,
                                    color: AppColor.warningColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    c,
                                    style: const TextStyle(
                                      color: AppColor.warningColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceLG),
                  ],
                  if (helper.suitabilityReasons.isNotEmpty) ...[
                    SectionTitle('Why ${profile.fullName.split(' ').first}?'),
                    const SizedBox(height: AppTheme.spaceSM),
                    _SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final reason in helper.suitabilityReasons)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: AppColor.accentColor
                                          .withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: AppColor.accentColor,
                                      size: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      reason,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  // Clearance under the sticky action bar at the bottom.
                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileHeroDelegate extends SliverPersistentHeaderDelegate {
  final HelperBookingProfile profile;
  _ProfileHeroDelegate({required this.profile});

  @override
  double get minExtent => 280;
  @override
  double get maxExtent => 280;

  @override
  Widget build(BuildContext context, double shrink, bool overlap) {
    final mediaTop = MediaQuery.of(context).padding.top;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: kBrandGradient,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: kBrandGradient.first.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: mediaTop + 4,
            left: 4,
            child: Material(
              color: Colors.white.withValues(alpha: 0.18),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).maybePop(),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
              ),
            ),
          ),
          Positioned.fill(
            top: mediaTop + 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: AppNetworkImage(
                    imageUrl: profile.profileImageUrl,
                    width: 100,
                    height: 100,
                    borderRadius: 50,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMD),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        profile.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFD56B),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      profile.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      ' (${profile.ratingCount})',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceSM),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: [
                    if ((profile.gender ?? '').isNotEmpty)
                      _OnHeroPill(label: profile.gender!),
                    if (profile.age != null)
                      _OnHeroPill(label: '${profile.age} y/o'),
                    _OnHeroPill(
                      label: '${profile.experienceYears}y exp',
                      icon: Icons.workspace_premium_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

class _SoftCard extends StatelessWidget {
  final Widget child;
  const _SoftCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatsRow extends StatelessWidget {
  final HelperBookingProfile profile;
  const _StatsRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    final acceptance = profile.acceptanceRate ?? 0;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.task_alt_rounded,
            label: 'Trips',
            value: profile.completedTrips.toString(),
            color: AppColor.accentColor,
          ),
        ),
        const SizedBox(width: AppTheme.spaceSM),
        Expanded(
          child: _StatCard(
            icon: Icons.bolt_rounded,
            label: 'Response',
            value: _responseLabel(profile.averageResponseTimeSeconds),
            color: AppColor.secondaryColor,
          ),
        ),
        const SizedBox(width: AppTheme.spaceSM),
        Expanded(
          child: _StatCard(
            icon: Icons.verified_user_rounded,
            label: 'Acceptance',
            value: '${(acceptance * 100).round()}%',
            color: acceptance >= 0.8
                ? AppColor.accentColor
                : (acceptance >= 0.5
                    ? AppColor.warningColor
                    : AppColor.errorColor),
          ),
        ),
      ],
    );
  }

  static String _responseLabel(int? seconds) {
    if (seconds == null) return 'â€”';
    if (seconds < 60) return '${seconds}s';
    return '${seconds ~/ 60}m';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMD,
        vertical: AppTheme.spaceMD,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColor.lightTextSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final HelperLanguage language;
  const _LanguageChip({required this.language});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSM,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColor.secondaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
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
                ? AppColor.accentColor
                : AppColor.secondaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            '${language.languageName}'
            '${language.level == null ? '' : ' Â· ${language.level}'}',
            style: const TextStyle(
              color: AppColor.secondaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceAreaChip extends StatelessWidget {
  final HelperServiceArea area;
  const _ServiceAreaChip({required this.area});

  @override
  Widget build(BuildContext context) {
    final label = [
      area.city,
      if ((area.areaName ?? '').isNotEmpty) area.areaName,
      area.country,
    ].whereType<String>().join(', ');
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSM,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColor.lightBorder,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.place_rounded,
            size: 14,
            color: AppColor.lightTextSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColor.lightTextSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CarCard extends StatelessWidget {
  final HelperCarInfo car;
  const _CarCard({required this.car});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final desc = [car.brand, car.model, car.color, car.type]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' Â· ');
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColor.warningColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: AppColor.warningColor,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Text(
              desc.isEmpty ? 'Helper has a vehicle' : desc,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnHeroPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  const _OnHeroPill({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientCta extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GradientCta({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            gradient: const LinearGradient(
              colors: [AppColor.accentColor, AppColor.secondaryColor],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColor.accentColor.withValues(alpha: 0.32),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      children: const [
        SizedBox(height: 60),
        Center(
          child: SkeletonBox(width: 100, height: 100, borderRadius: 50),
        ),
        SizedBox(height: AppTheme.spaceMD),
        Center(child: SkeletonBox(height: 22, width: 180)),
        SizedBox(height: 8),
        Center(child: SkeletonBox(height: 14, width: 120)),
        SizedBox(height: AppTheme.spaceLG),
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 80, width: double.infinity)),
            SizedBox(width: 8),
            Expanded(child: SkeletonBox(height: 80, width: double.infinity)),
            SizedBox(width: 8),
            Expanded(child: SkeletonBox(height: 80, width: double.infinity)),
          ],
        ),
        SizedBox(height: AppTheme.spaceLG),
        SkeletonBox(height: 60, width: double.infinity),
        SizedBox(height: AppTheme.spaceLG),
        SkeletonBox(height: 40, width: 200),
        SizedBox(height: 12),
        SkeletonBox(height: 60, width: double.infinity),
      ],
    );
  }
}
