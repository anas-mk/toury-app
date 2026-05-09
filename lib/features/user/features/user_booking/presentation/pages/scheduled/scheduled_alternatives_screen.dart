import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/di/injection_container.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/theme/brand_typography.dart';
import '../../../../../../../core/widgets/brand/brand_kit.dart';
import '../../../domain/entities/alternatives_response.dart';
import '../../../domain/entities/helper_search_result.dart';
import '../../cubits/scheduled/scheduled_alternatives_cubit.dart';

/// Phase 5 \u2014 alternative-helpers screen for a Scheduled booking that
/// the original helper declined / let expire.
///
/// Reuses [GetAlternativesUC] (the REST endpoint is shared across
/// instant + scheduled flows) via [ScheduledAlternativesCubit].
class ScheduledAlternativesScreen extends StatelessWidget {
  final String bookingId;
  const ScheduledAlternativesScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ScheduledAlternativesCubit>(
      create: (_) => sl<ScheduledAlternativesCubit>()..load(bookingId),
      child: _AlternativesView(bookingId: bookingId),
    );
  }
}

class _AlternativesView extends StatelessWidget {
  final String bookingId;
  const _AlternativesView({required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      body: BlocBuilder<ScheduledAlternativesCubit,
          ScheduledAlternativesState>(
        builder: (context, state) {
          if (state is ScheduledAlternativesLoading ||
              state is ScheduledAlternativesInitial) {
            return const _Loading();
          }
          if (state is ScheduledAlternativesError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context
                  .read<ScheduledAlternativesCubit>()
                  .load(bookingId),
            );
          }
          if (state is ScheduledAlternativesLoaded) {
            return _LoadedView(data: state.data);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final AlternativesResponse data;
  const _LoadedView({required this.data});

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
            'Pick another helper',
            style: BrandTypography.title(weight: FontWeight.w700),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          sliver: SliverList.list(
            children: [
              _HeaderCard(data: data),
              if (data.assignmentHistory.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Previous attempts',
                  style: BrandTypography.body(weight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...data.assignmentHistory.map((a) => _HistoryRow(attempt: a)),
              ],
              const SizedBox(height: 20),
              Text(
                data.alternativeHelpers.isEmpty
                    ? 'No more helpers available'
                    : 'Available helpers (${data.alternativeHelpers.length})',
                style: BrandTypography.body(weight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (data.alternativeHelpers.isEmpty)
                _EmptyAlternatives(autoRetryActive: data.autoRetryActive)
              else
                ...data.alternativeHelpers.map(
                  (h) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _HelperCard(helper: h),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final AlternativesResponse data;
  const _HeaderCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final progress = data.maxAttempts == 0
        ? 0.0
        : (data.attemptsMade / data.maxAttempts).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BrandTokens.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: data.autoRetryActive
                      ? BrandTokens.accentAmberSoft
                      : BrandTokens.borderTinted,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  data.autoRetryActive
                      ? Icons.autorenew_rounded
                      : Icons.swap_horiz_rounded,
                  color: data.autoRetryActive
                      ? BrandTokens.accentAmberText
                      : BrandTokens.primaryBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.message,
                  style: BrandTypography.body(weight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: BrandTokens.bgSoft,
              valueColor: const AlwaysStoppedAnimation<Color>(
                BrandTokens.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Attempt ${data.attemptsMade} of ${data.maxAttempts}',
            style: BrandTypography.caption(),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final AssignmentAttempt attempt;
  const _HistoryRow({required this.attempt});

  @override
  Widget build(BuildContext context) {
    final palette = _palette(attempt.responseStatus);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BrandTokens.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: palette.bg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${attempt.attemptOrder}',
              style: BrandTypography.caption(
                weight: FontWeight.w700,
                color: palette.fg,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attempt.helperName,
                  style: BrandTypography.body(weight: FontWeight.w600),
                ),
                if (attempt.respondedAt != null)
                  Text(
                    _format(attempt.respondedAt!),
                    style: BrandTypography.caption(),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: palette.bg,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              attempt.responseStatus,
              style: BrandTypography.caption(
                weight: FontWeight.w700,
                color: palette.fg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ({Color fg, Color bg}) _palette(String s) {
    switch (s.toLowerCase()) {
      case 'accepted':
        return (
          fg: BrandTokens.successGreen,
          bg: BrandTokens.successGreenSoft,
        );
      case 'declined':
      case 'cancelledbysystem':
        return (
          fg: BrandTokens.dangerRed,
          bg: BrandTokens.dangerRedSoft,
        );
      case 'expired':
        return (
          fg: BrandTokens.accentAmberText,
          bg: BrandTokens.accentAmberSoft,
        );
      default:
        return (
          fg: BrandTokens.textSecondary,
          bg: BrandTokens.bgSoft,
        );
    }
  }

  static String _format(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _HelperCard extends StatelessWidget {
  final HelperSearchResult helper;
  const _HelperCard({required this.helper});

  @override
  Widget build(BuildContext context) {
    final initial = helper.fullName.isEmpty
        ? '?'
        : helper.fullName.substring(0, 1).toUpperCase();
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        // Picking a new helper from this screen requires the original
        // search context (same params, new helperId). We surface an
        // info snackbar prompting the user to start a fresh search,
        // since the create-booking call needs the full ScheduledSearchParams
        // and we don\u2019t have them on this stand-alone screen.
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Open the helper from your search results to book them.',
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: BrandTokens.surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: BrandTokens.borderSoft),
        ),
        child: Row(
          children: [
            ClipOval(
              child: helper.profileImageUrl == null ||
                      helper.profileImageUrl!.isEmpty
                  ? Container(
                      width: 56,
                      height: 56,
                      color: BrandTokens.borderTinted,
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: BrandTypography.title(
                          weight: FontWeight.w700,
                          color: BrandTokens.primaryBlue,
                        ),
                      ),
                    )
                  : Image.network(
                      helper.profileImageUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: BrandTokens.borderTinted,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.person_rounded,
                          color: BrandTokens.primaryBlue,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    helper.fullName,
                    style: BrandTypography.body(weight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFB45309),
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        helper.rating.toStringAsFixed(1),
                        style: BrandTypography.caption(
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('\u2022', style: BrandTypography.caption()),
                      const SizedBox(width: 6),
                      Text(
                        '${helper.completedTrips} trips',
                        style: BrandTypography.caption(),
                      ),
                    ],
                  ),
                ],
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

class _EmptyAlternatives extends StatelessWidget {
  final bool autoRetryActive;
  const _EmptyAlternatives({required this.autoRetryActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BrandTokens.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            autoRetryActive
                ? Icons.hourglass_top_rounded
                : Icons.search_off_rounded,
            color: BrandTokens.textSecondary,
            size: 28,
          ),
          const SizedBox(height: 10),
          Text(
            autoRetryActive
                ? 'Looking for more helpers\u2026'
                : 'No more helpers in your area',
            style: BrandTypography.body(weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            autoRetryActive
                ? 'We\u2019ll keep trying. You can also start a new search '
                    'with a different time window.'
                : 'Try widening your time window or starting a fresh search.',
            style: BrandTypography.caption(
              color: BrandTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        SkeletonShimmer(child: SkeletonBlock(height: 80, radius: 20)),
        SizedBox(height: 16),
        SkeletonShimmer(child: SkeletonBlock(height: 60, radius: 14)),
        SizedBox(height: 8),
        SkeletonShimmer(child: SkeletonBlock(height: 60, radius: 14)),
        SizedBox(height: 16),
        SkeletonShimmer(child: SkeletonBlock(height: 80, radius: 20)),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
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
              'Couldn\u2019t load alternatives',
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
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
