import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/di/injection_container.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/theme/brand_typography.dart';
import '../../../../../../../core/widgets/brand/brand_kit.dart';
import '../../../domain/entities/helper_booking_entity.dart';
import '../../../domain/entities/helper_booking_profile.dart';
import '../../../domain/entities/search_params.dart';
import '../../cubits/helper_booking_profile_cubit.dart';

/// Phase 3 — full helper profile (languages, certs, service areas, car)
/// before booking.
///
/// Reuses [HelperBookingProfileCubit] (REST endpoint `/user/bookings/helpers/{id}/profile`
/// is shared across instant and scheduled flows).
class ScheduledHelperProfileScreen extends StatelessWidget {
  final String helperId;
  final HelperBookingEntity? initialHelper;
  final ScheduledSearchParams? searchParams;

  const ScheduledHelperProfileScreen({
    super.key,
    required this.helperId,
    this.initialHelper,
    this.searchParams,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HelperBookingProfileCubit>(
      create: (_) => sl<HelperBookingProfileCubit>()..load(helperId),
      child: _ProfileView(
        helperId: helperId,
        initialHelper: initialHelper,
        searchParams: searchParams,
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  final String helperId;
  final HelperBookingEntity? initialHelper;
  final ScheduledSearchParams? searchParams;

  const _ProfileView({
    required this.helperId,
    this.initialHelper,
    this.searchParams,
  });

  void _onContinue(BuildContext context) {
    if (searchParams == null || initialHelper == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile opened in read-only mode. Start a search to book.',
          ),
        ),
      );
      return;
    }

    context.push(
      AppRouter.scheduledReview,
      extra: {
        'helper': initialHelper,
        'params': searchParams,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      bottomCta: BlocBuilder<HelperBookingProfileCubit,
          HelperBookingProfileState>(
        builder: (context, state) {
          final ready = state is HelperBookingProfileLoaded &&
              searchParams != null &&
              initialHelper != null;
          return PrimaryGradientButton(
            label: 'Continue to review',
            icon: Icons.arrow_forward_rounded,
            onPressed: ready ? () => _onContinue(context) : null,
            visualEnabled: ready,
          );
        },
      ),
      body: BlocBuilder<HelperBookingProfileCubit, HelperBookingProfileState>(
        builder: (context, state) {
          if (state is HelperBookingProfileLoading ||
              state is HelperBookingProfileInitial) {
            return const _LoadingState();
          }
          if (state is HelperBookingProfileError) {
            return _ErrorState(
              message: state.message,
              onRetry: () => context
                  .read<HelperBookingProfileCubit>()
                  .load(helperId),
            );
          }
          if (state is HelperBookingProfileLoaded) {
            return _LoadedView(profile: state.profile);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final HelperBookingProfile profile;
  const _LoadedView({required this.profile});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: BrandTokens.bgSoft,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: BrandTokens.textPrimary),
          title: Text(
            'Helper profile',
            style: BrandTypography.title(weight: FontWeight.w700),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          sliver: SliverList.list(
            children: [
              _HeroCard(profile: profile),
              const SizedBox(height: 16),
              _StatsRow(profile: profile),
              if (profile.bio != null && profile.bio!.trim().isNotEmpty) ...[
                const SizedBox(height: 24),
                _SectionTitle('About'),
                const SizedBox(height: 8),
                Text(
                  profile.bio!,
                  style: BrandTypography.body(
                    color: BrandTokens.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _SectionTitle('Languages'),
              const SizedBox(height: 8),
              _LanguagesSection(languages: profile.languages),
              const SizedBox(height: 24),
              _SectionTitle('Service areas'),
              const SizedBox(height: 8),
              _ServiceAreasSection(areas: profile.serviceAreas),
              if (profile.hasCar && profile.car != null) ...[
                const SizedBox(height: 24),
                _SectionTitle('Vehicle'),
                const SizedBox(height: 8),
                _CarCard(car: profile.car!),
              ],
              if (profile.certificates.isNotEmpty) ...[
                const SizedBox(height: 24),
                _SectionTitle('Certificates'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.certificates
                      .map((c) => _CertChip(label: c))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final HelperBookingProfile profile;
  const _HeroCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final initials = profile.fullName.isEmpty
        ? '?'
        : profile.fullName.substring(0, 1).toUpperCase();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: BrandTokens.borderSoft),
      ),
      child: Row(
        children: [
          ClipOval(
            child: profile.profileImageUrl == null ||
                    profile.profileImageUrl!.isEmpty
                ? Container(
                    width: 84,
                    height: 84,
                    color: BrandTokens.borderTinted,
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: BrandTypography.headline(
                        color: BrandTokens.primaryBlue,
                      ),
                    ),
                  )
                : Image.network(
                    profile.profileImageUrl!,
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 84,
                      height: 84,
                      color: BrandTokens.borderTinted,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.person_rounded,
                        color: BrandTokens.primaryBlue,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  style: BrandTypography.headline(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFB45309),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      profile.rating.toStringAsFixed(1),
                      style: BrandTypography.body(
                        weight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      ' (${profile.ratingCount})',
                      style: BrandTypography.caption(),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: BrandTokens.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${profile.experienceYears}y exp',
                      style: BrandTypography.caption(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: BrandTokens.successGreenSoft,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${profile.hourlyRate.toStringAsFixed(0)} EGP / hr',
                    style: BrandTypography.caption(
                      color: BrandTokens.successGreen,
                      weight: FontWeight.w700,
                    ),
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

class _StatsRow extends StatelessWidget {
  final HelperBookingProfile profile;
  const _StatsRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    final responseSeconds = profile.averageResponseTimeSeconds;
    final acceptanceRate = profile.acceptanceRate;

    final responseLabel = responseSeconds == null
        ? '\u2014'
        : responseSeconds < 60
            ? '${responseSeconds}s'
            : '${(responseSeconds / 60).round()}m';

    final acceptanceLabel = acceptanceRate == null
        ? '\u2014'
        : '${(acceptanceRate * 100).toStringAsFixed(0)}%';

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.flight_takeoff_rounded,
            label: 'Trips',
            value: profile.completedTrips.toString(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.bolt_rounded,
            label: 'Avg reply',
            value: responseLabel,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.check_circle_rounded,
            label: 'Acceptance',
            value: acceptanceLabel,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandTokens.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: BrandTokens.primaryBlue),
          const SizedBox(height: 6),
          Text(value, style: BrandTypography.title(weight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: BrandTypography.caption()),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: BrandTypography.body(weight: FontWeight.w700),
    );
  }
}

class _LanguagesSection extends StatelessWidget {
  final List<HelperLanguage> languages;
  const _LanguagesSection({required this.languages});

  @override
  Widget build(BuildContext context) {
    if (languages.isEmpty) {
      return Text(
        'No language data shared.',
        style: BrandTypography.caption(),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: languages.map((l) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: BrandTokens.surfaceWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: BrandTokens.borderSoft),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.languageName,
                style: BrandTypography.body(weight: FontWeight.w600),
              ),
              if (l.level != null) ...[
                const SizedBox(width: 6),
                Text(
                  '\u2022 ${l.level!}',
                  style: BrandTypography.caption(),
                ),
              ],
              if (l.isVerified) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.verified_rounded,
                  size: 14,
                  color: BrandTokens.primaryBlue,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ServiceAreasSection extends StatelessWidget {
  final List<HelperServiceArea> areas;
  const _ServiceAreasSection({required this.areas});

  @override
  Widget build(BuildContext context) {
    if (areas.isEmpty) {
      return Text(
        'No service areas listed.',
        style: BrandTypography.caption(),
      );
    }
    return Column(
      children: areas.map((a) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BrandTokens.surfaceWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: BrandTokens.borderSoft),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.place_rounded,
                color: BrandTokens.primaryBlue,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.areaName == null
                          ? a.city
                          : '${a.areaName}, ${a.city}',
                      style: BrandTypography.body(weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a.country,
                      style: BrandTypography.caption(),
                    ),
                  ],
                ),
              ),
              if (a.isPrimary)
                const StatusPill(
                  status: BrandStatus.info,
                  label: 'Primary',
                  dense: true,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CarCard extends StatelessWidget {
  final HelperCarInfo car;
  const _CarCard({required this.car});

  @override
  Widget build(BuildContext context) {
    final parts = [car.brand, car.model].whereType<String>().toList();
    final title = parts.isEmpty ? 'Vehicle' : parts.join(' ');
    final color = car.color;
    final type = car.type;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BrandTokens.borderSoft),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.directions_car_filled_rounded,
            color: BrandTokens.primaryBlue,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: BrandTypography.body(weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  [color, type].whereType<String>().join(' \u2022 '),
                  style: BrandTypography.caption(),
                ),
              ],
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: BrandTokens.accentAmberSoft,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: BrandTokens.accentAmberBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            color: Color(0xFFB45309),
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: BrandTypography.caption(
              color: BrandTokens.accentAmberText,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        SkeletonShimmer(
          child: SkeletonBlock(height: 120, radius: 24),
        ),
        SizedBox(height: 16),
        SkeletonShimmer(
          child: Row(
            children: [
              Expanded(child: SkeletonBlock(height: 64, radius: 16)),
              SizedBox(width: 10),
              Expanded(child: SkeletonBlock(height: 64, radius: 16)),
              SizedBox(width: 10),
              Expanded(child: SkeletonBlock(height: 64, radius: 16)),
            ],
          ),
        ),
        SizedBox(height: 24),
        SkeletonShimmer(child: SkeletonBlock(height: 72, radius: 14)),
        SizedBox(height: 12),
        SkeletonShimmer(child: SkeletonBlock(height: 72, radius: 14)),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 56,
            color: BrandTokens.dangerRed,
          ),
          const SizedBox(height: 16),
          Text(
            'Couldn\u2019t load profile',
            style: BrandTypography.title(weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: BrandTypography.caption(),
          ),
          const SizedBox(height: 16),
          GhostButton(
            label: 'Try again',
            icon: Icons.refresh_rounded,
            onPressed: () {
              HapticFeedback.selectionClick();
              onRetry();
            },
          ),
        ],
      ),
    );
  }
}
