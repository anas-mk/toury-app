import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/di/injection_container.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/utils/number_format.dart';
import '../../../../../../../core/widgets/app_network_image.dart';
import '../../../domain/entities/helper_booking_profile.dart';
import '../../../domain/entities/helper_search_result.dart';
import '../../cubits/helper_booking_profile_cubit.dart';
import '../../cubits/instant_booking_cubit.dart';
import '../../widgets/instant/empty_error_state.dart';
import '../../widgets/instant/skeleton.dart';
import 'location_pick_result.dart';

/// Step 5 — full helper profile page (Pass #6 — 2026 editorial redesign).
///
/// Matches the RAFIQ HTML mockup:
///   • Cream `#FAF8F4` page with a flat sticky top bar.
///   • Hero card with an avatar that overflows the top edge, name,
///     ★ rating + review count, and a warm-amber hourly-rate pill.
///   • Three-up "trust strip" (Trips · Response · Accept).
///   • About paragraph.
///   • Languages + Certificates two-column bento.
///   • Service Areas list.
///   • Vehicle card.
///   • Sticky "Book with {first name}" CTA at the bottom that pushes
///     directly to the Confirm Booking screen.
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

  void _onBook(BuildContext context) {
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF8F4),
        body: BlocBuilder<HelperBookingProfileCubit,
            HelperBookingProfileState>(
          builder: (context, state) {
            if (state is HelperBookingProfileError) {
              return _ErrorView(
                message: state.message,
                onRetry: () => context
                    .read<HelperBookingProfileCubit>()
                    .load(helper.helperId),
              );
            }
            if (state is HelperBookingProfileLoaded) {
              return _LoadedScaffold(
                profile: state.profile,
                helper: helper,
                onBook: () => _onBook(context),
              );
            }
            return const _ProfileSkeleton();
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error / loading
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ErrorRetryState(message: message, onRetry: onRetry),
        ),
        const _SimpleTopBar(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loaded scaffold (top bar + scrollable body + sticky CTA)
// ─────────────────────────────────────────────────────────────────────────────

class _LoadedScaffold extends StatelessWidget {
  final HelperBookingProfile profile;
  final HelperSearchResult helper;
  final VoidCallback onBook;
  const _LoadedScaffold({
    required this.profile,
    required this.helper,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // The top bar lives in the sliver list (sticky) so the
              // body content scrolls cleanly behind it without weird
              // padding tricks.
              const SliverAppBar(
                pinned: true,
                floating: false,
                elevation: 0,
                scrolledUnderElevation: 0,
                automaticallyImplyLeading: false,
                centerTitle: false,
                backgroundColor: Color(0xFFFAF8F4),
                surfaceTintColor: Color(0xFFFAF8F4),
                toolbarHeight: 64,
                titleSpacing: 0,
                title: _TopBarRow(),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                  child: Column(
                    children: [
                      _HeroCard(profile: profile),
                      const SizedBox(height: 32),
                      _StatsRow(profile: profile),
                      if ((profile.bio ?? '').isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _SectionTitle('ABOUT'),
                        const SizedBox(height: 12),
                        _AboutText(text: profile.bio!),
                      ],
                      const SizedBox(height: 32),
                      _BentoLanguagesCertificates(profile: profile),
                      if (profile.serviceAreas.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _SectionTitle('SERVICE AREAS'),
                        const SizedBox(height: 12),
                        _ServiceAreasList(areas: profile.serviceAreas),
                      ],
                      if (profile.hasCar && profile.car != null) ...[
                        const SizedBox(height: 32),
                        _VehicleCard(car: profile.car!),
                      ],
                      if (helper.suitabilityReasons.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _SectionTitle(
                          'WHY ${profile.fullName.split(' ').first.toUpperCase()}?',
                        ),
                        const SizedBox(height: 12),
                        _ReasonsList(reasons: helper.suitabilityReasons),
                      ],
                      // Bottom inset so the sticky CTA never covers
                      // the last card.
                      const SizedBox(height: 140),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _BookingDock(
            firstName: profile.fullName.split(' ').first,
            onTap: onBook,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar (back pill + RAFIQ + explore)
// ─────────────────────────────────────────────────────────────────────────────

class _TopBarRow extends StatelessWidget {
  const _TopBarRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CircleIconButton(
            icon: Icons.arrow_back_rounded,
            background: const Color(0xFFE4E1EA),
            foreground: const Color(0xFF464652),
            onTap: () {
              HapticFeedback.selectionClick();
              context.pop();
            },
          ),
          Text(
            BrandTokens.wordmark,
            style: BrandTokens.heading(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: BrandTokens.primaryBlue,
              letterSpacing: -1.0,
            ),
          ),
          _CircleIconButton(
            icon: Icons.explore_outlined,
            background: Colors.transparent,
            foreground: const Color(0xFF767683),
            onTap: () {
              HapticFeedback.selectionClick();
              final ctrl = PrimaryScrollController.maybeOf(context);
              if (ctrl != null && ctrl.hasClients) {
                ctrl.animateTo(
                  0,
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  const _CircleIconButton({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: foreground, size: 22),
        ),
      ),
    );
  }
}

/// Floating top bar used on the error state where there's no scaffold
/// scroll context (rendered in the [Stack] above the empty-state).
class _SimpleTopBar extends StatelessWidget {
  const _SimpleTopBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CircleIconButton(
                icon: Icons.arrow_back_rounded,
                background: const Color(0xFFE4E1EA),
                foreground: const Color(0xFF464652),
                onTap: () => context.pop(),
              ),
              Text(
                BrandTokens.wordmark,
                style: BrandTokens.heading(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: BrandTokens.primaryBlue,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero card (avatar overflows top, name, rating, hourly-rate pill)
// ─────────────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final HelperBookingProfile profile;
  const _HeroCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 50),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
          decoration: BoxDecoration(
            color: BrandTokens.surfaceWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: BrandTokens.shadowSoft,
                blurRadius: 30,
                spreadRadius: -8,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                profile.fullName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BrandTokens.heading(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: BrandTokens.textPrimary,
                  letterSpacing: -0.5,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              _RatingRow(
                rating: profile.rating,
                ratingCount: profile.ratingCount,
              ),
              const SizedBox(height: 14),
              _HourlyRatePill(rate: profile.hourlyRate),
            ],
          ),
        ),
        // Floating avatar.
        Positioned(
          top: 0,
          child: Hero(
            tag: 'helper-avatar-${profile.helperId}',
            child: _Avatar(imageUrl: profile.profileImageUrl),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? imageUrl;
  const _Avatar({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFAF8F4),
        border: Border.all(color: const Color(0xFFFAF8F4), width: 5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: AppNetworkImage(
          imageUrl: imageUrl,
          width: 90,
          height: 90,
          borderRadius: 45,
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final double rating;
  final int ratingCount;
  const _RatingRow({required this.rating, required this.ratingCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.star_rounded,
          size: 20,
          color: Color(0xFFFE9331),
        ),
        const SizedBox(width: 4),
        Text(
          context.localizeNumber(rating, decimals: 1),
          style: const TextStyle(
            color: BrandTokens.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '(${context.localizeNumber(ratingCount)} reviews)',
          style: const TextStyle(
            color: Color(0xFF767683),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _HourlyRatePill extends StatelessWidget {
  final double rate;
  const _HourlyRatePill({required this.rate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF924C00),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF924C00).withValues(alpha: 0.20),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.payments_rounded,
            size: 18,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            '${context.localizeNumber(rate, decimals: 0)} EGP/hr',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats row (3 cards: trips · response · accept)
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final HelperBookingProfile profile;
  const _StatsRow({required this.profile});

  static String _responseLabel(int? seconds, BuildContext context) {
    if (seconds == null) return '—';
    if (seconds < 60) {
      return '${context.localizeNumber(seconds)}s';
    }
    return '${context.localizeNumber(seconds ~/ 60)}m';
  }

  @override
  Widget build(BuildContext context) {
    final acc = (profile.acceptanceRate ?? 0) * 100;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: context.localizeNumber(profile.completedTrips),
            label: 'TRIPS',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: _responseLabel(
                profile.averageResponseTimeSeconds, context),
            label: 'RESPONSE',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: '${context.localizeNumber(acc.round())}%',
            label: 'ACCEPT',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: BrandTokens.shadowSoft,
            blurRadius: 30,
            spreadRadius: -8,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BrandTokens.heading(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: BrandTokens.primaryBlue,
              height: 1.0,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF767683),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section title with bottom rule
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE4E1EA), width: 1),
        ),
      ),
      child: Text(
        label,
        style: BrandTokens.heading(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: BrandTokens.primaryBlue,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}

class _AboutText extends StatelessWidget {
  final String text;
  const _AboutText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF464652),
        fontSize: 16,
        height: 1.6,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bento (Languages | Certificates)
// ─────────────────────────────────────────────────────────────────────────────

class _BentoLanguagesCertificates extends StatelessWidget {
  final HelperBookingProfile profile;
  const _BentoLanguagesCertificates({required this.profile});

  @override
  Widget build(BuildContext context) {
    final hasLangs = profile.languages.isNotEmpty;
    final hasCerts = profile.certificates.isNotEmpty;
    if (!hasLangs && !hasCerts) return const SizedBox.shrink();

    final isWide = MediaQuery.of(context).size.width >= 600;
    final cards = <Widget>[
      if (hasLangs)
        _BentoCard(
          label: 'LANGUAGES',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < profile.languages.length; i++)
                _LangChip(
                  language: profile.languages[i],
                  primary: i == 0,
                ),
            ],
          ),
        ),
      if (hasCerts)
        _BentoCard(
          label: 'CERTIFICATES',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in profile.certificates) _CertChip(label: c),
            ],
          ),
        ),
    ];

    if (isWide && cards.length == 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 16),
          Expanded(child: cards[1]),
        ],
      );
    }
    return Column(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          cards[i],
        ],
      ],
    );
  }
}

class _BentoCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _BentoCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: BrandTokens.shadowSoft,
            blurRadius: 30,
            spreadRadius: -8,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF767683),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final HelperLanguage language;

  /// First language is rendered in primary-container blue (matches the
  /// mockup's "native" highlight); the rest use a neutral surface.
  final bool primary;
  const _LangChip({required this.language, required this.primary});

  @override
  Widget build(BuildContext context) {
    final bg = primary
        ? const Color(0xFF1B237E)
        : const Color(0xFFE4E1EA);
    final fg = primary ? const Color(0xFF8790EE) : const Color(0xFF464652);
    final mainColor =
        primary ? Colors.white : const Color(0xFF1B1B21);
    final hasLevel = (language.level ?? '').isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            language.languageName,
            style: TextStyle(
              color: mainColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (hasLevel) ...[
            const SizedBox(width: 6),
            Text(
              language.level!.toUpperCase(),
              style: TextStyle(
                color: fg,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CertChip extends StatelessWidget {
  final String label;
  const _CertChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF924C00).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF924C00).withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_rounded,
            size: 16,
            color: Color(0xFF924C00),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF924C00),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service areas list
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceAreasList extends StatelessWidget {
  final List<HelperServiceArea> areas;
  const _ServiceAreasList({required this.areas});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < areas.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _ServiceAreaTile(area: areas[i]),
        ],
      ],
    );
  }
}

class _ServiceAreaTile extends StatelessWidget {
  final HelperServiceArea area;
  const _ServiceAreaTile({required this.area});

  @override
  Widget build(BuildContext context) {
    final title = area.areaName?.isNotEmpty == true
        ? area.areaName!
        : area.city;
    final subtitle = area.areaName?.isNotEmpty == true
        ? area.city
        : (area.country.isNotEmpty ? area.country : null);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.location_on_rounded,
            color: Color(0xFF767683),
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: BrandTokens.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF464652),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vehicle card
// ─────────────────────────────────────────────────────────────────────────────

class _VehicleCard extends StatelessWidget {
  final HelperCarInfo car;
  const _VehicleCard({required this.car});

  String get _title {
    final parts = [car.brand, car.model]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? 'Personal vehicle' : parts.join(' ');
  }

  String? get _subtitle {
    final parts = [car.color, car.type]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: BrandTokens.shadowSoft,
            blurRadius: 30,
            spreadRadius: -8,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: BrandTokens.primaryBlue.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: BrandTokens.primaryBlue,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'VEHICLE',
                  style: TextStyle(
                    color: Color(0xFF767683),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _title,
                  style: const TextStyle(
                    color: BrandTokens.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _subtitle!,
                    style: const TextStyle(
                      color: Color(0xFF464652),
                      fontSize: 14,
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

// ─────────────────────────────────────────────────────────────────────────────
// Reasons (kept from old design — gives extra justification ABOVE the dock)
// ─────────────────────────────────────────────────────────────────────────────

class _ReasonsList extends StatelessWidget {
  final List<String> reasons;
  const _ReasonsList({required this.reasons});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: BrandTokens.shadowSoft,
            blurRadius: 30,
            spreadRadius: -8,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < reasons.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 3),
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
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    reasons[i],
                    style: const TextStyle(
                      color: BrandTokens.textPrimary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky CTA dock (gradient fade above + filled pill button)
// ─────────────────────────────────────────────────────────────────────────────

class _BookingDock extends StatelessWidget {
  final String firstName;
  final VoidCallback onTap;
  const _BookingDock({required this.firstName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color(0xFFFAF8F4),
            Color(0xE6FAF8F4),
            Color(0x00FAF8F4),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: _BookCtaButton(
            label: 'Book with $firstName',
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}

class _BookCtaButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _BookCtaButton({required this.label, required this.onTap});

  @override
  State<_BookCtaButton> createState() => _BookCtaButtonState();
}

class _BookCtaButtonState extends State<_BookCtaButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _down ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: BrandTokens.primaryBlue,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: BrandTokens.primaryBlue.withValues(alpha: 0.30),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton (light, editorial — matches the new layout)
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(24, 80, 24, 100),
          children: [
            // Avatar circle.
            Center(
              child: SkeletonBox(
                width: 100,
                height: 100,
                borderRadius: 50,
              ),
            ),
            const SizedBox(height: 24),
            // Hero card placeholder.
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: BrandTokens.surfaceWhite,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  SkeletonBox(height: 22, width: 180),
                  SizedBox(height: 12),
                  SkeletonBox(height: 14, width: 140),
                  SizedBox(height: 16),
                  SkeletonBox(height: 36, width: 160, borderRadius: 40),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Stats row.
            const Row(
              children: [
                Expanded(
                  child: SkeletonBox(
                    height: 90,
                    width: double.infinity,
                    borderRadius: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: SkeletonBox(
                    height: 90,
                    width: double.infinity,
                    borderRadius: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: SkeletonBox(
                    height: 90,
                    width: double.infinity,
                    borderRadius: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const SkeletonBox(
              height: 80,
              width: double.infinity,
              borderRadius: 16,
            ),
            const SizedBox(height: 24),
            const SkeletonBox(
              height: 120,
              width: double.infinity,
              borderRadius: 20,
            ),
          ],
        ),
        const _SimpleTopBar(),
      ],
    );
  }
}
