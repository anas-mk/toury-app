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
import '../../../domain/entities/search_params.dart';
import '../../cubits/search_helpers_cubit.dart';
import '../../cubits/search_helpers_state.dart';

class ScheduledSearchResultsScreen extends StatefulWidget {
  final ScheduledSearchParams params;

  const ScheduledSearchResultsScreen({super.key, required this.params});

  @override
  State<ScheduledSearchResultsScreen> createState() =>
      _ScheduledSearchResultsScreenState();
}

class _ScheduledSearchResultsScreenState
    extends State<ScheduledSearchResultsScreen> {
  late ScheduledSearchParams _params;

  @override
  void initState() {
    super.initState();
    _params = widget.params;
  }

  void _applyFilters(ScheduledSearchParams updated) {
    setState(() => _params = updated);
    context.read<SearchHelpersCubit>().searchScheduled(updated);
  }

  Future<void> _onRefresh() async {
    HapticFeedback.selectionClick();
    await context.read<SearchHelpersCubit>().searchScheduled(_params);
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(params: _params, onApply: _applyFilters),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SearchHelpersCubit>(
      create: (_) => sl<SearchHelpersCubit>()..searchScheduled(_params),
      child: Builder(
        builder: (context) {
          return PageScaffold(
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: BrandTokens.bgSoft,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: const IconThemeData(
                    color: BrandTokens.textPrimary,
                  ),
                  title: Text(
                    'Available helpers',
                    style: BrandTypography.title(weight: FontWeight.w700),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.tune_rounded,
                        color: BrandTokens.textPrimary,
                      ),
                      tooltip: 'Filter & sort',
                      onPressed: _showFilterSheet,
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: _SearchSummaryCard(params: _params),
                  ),
                ),
                BlocBuilder<SearchHelpersCubit, SearchHelpersState>(
                  builder: (context, state) {
                    if (state is SearchHelpersLoading ||
                        state is SearchHelpersInitial) {
                      return const SliverPadding(
                        padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
                        sliver: _LoadingSkeletons(),
                      );
                    }
                    if (state is SearchHelpersError) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: _ErrorState(
                          message: state.message,
                          onRetry: () => context
                              .read<SearchHelpersCubit>()
                              .searchScheduled(_params),
                        ),
                      );
                    }
                    if (state is SearchHelpersLoaded) {
                      if (state.helpers.isEmpty) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyState(),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        sliver: SliverList.list(
                          children: [
                            // Available count banner
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
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
                                      '${state.availableCount} helper${state.availableCount == 1 ? '' : 's'} available',
                                      style: BrandTypography.caption(
                                        color: BrandTokens.successGreen,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...state.helpers.map(
                              (h) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _HelperCard(
                                  helper: h,
                                  onTap: () => _openProfile(context, h),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  },
                ),
              ],
            ),
            bottomCta: BlocBuilder<SearchHelpersCubit, SearchHelpersState>(
              builder: (context, state) {
                final loading = state is SearchHelpersLoading;
                return GhostButton(
                  label: loading ? 'Refreshing…' : 'Refresh results',
                  icon: Icons.refresh_rounded,
                  onPressed: loading ? null : _onRefresh,
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _openProfile(BuildContext context, HelperBookingEntity helper) {
    context.push(
      AppRouter.scheduledHelperProfile.replaceFirst(':id', helper.id),
      extra: {'helper': helper, 'params': _params},
    );
  }
}

// ── Filter Sheet ──────────────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final ScheduledSearchParams params;
  final ValueChanged<ScheduledSearchParams> onApply;

  const _FilterSheet({required this.params, required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _sortBy;
  late String _sortOrder;
  double? _minRating;
  double? _maxPrice;
  String? _helperGender;

  static const _sortOptions = [
    ('MatchScore', 'Best match'),
    ('Price', 'Price'),
    ('Rating', 'Rating'),
    ('Experience', 'Experience'),
  ];

  @override
  void initState() {
    super.initState();
    _sortBy = widget.params.sortBy ?? 'MatchScore';
    _sortOrder = widget.params.sortOrder ?? 'Desc';
    _minRating = widget.params.minRating;
    _maxPrice = widget.params.maxPrice;
    _helperGender = widget.params.helperGender;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Filter & Sort', style: BrandTypography.headline()),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _sortBy = 'MatchScore';
                    _sortOrder = 'Desc';
                    _minRating = null;
                    _maxPrice = null;
                    _helperGender = null;
                  });
                },
                child: Text(
                  'Reset',
                  style: BrandTypography.body(color: BrandTokens.primaryBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sort by
          Text('Sort by', style: BrandTypography.body(weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sortOptions.map((opt) {
              final selected = _sortBy == opt.$1;
              return GestureDetector(
                onTap: () => setState(() => _sortBy = opt.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? BrandTokens.primaryBlue
                        : BrandTokens.bgSoft,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: selected
                          ? BrandTokens.primaryBlue
                          : BrandTokens.borderSoft,
                    ),
                  ),
                  child: Text(
                    opt.$2,
                    style: BrandTypography.body(
                      weight: FontWeight.w600,
                      color: selected ? Colors.white : BrandTokens.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Order:', style: BrandTypography.caption()),
              const SizedBox(width: 8),
              _OrderToggle(
                value: _sortOrder,
                onChanged: (v) => setState(() => _sortOrder = v),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Min rating
          Text(
            'Minimum rating',
            style: BrandTypography.body(weight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [null, 3.0, 4.0, 4.5].map((r) {
              final selected = _minRating == r;
              final label = r == null
                  ? 'Any'
                  : '${r % 1 == 0 ? r.toInt() : r}+';
              return GestureDetector(
                onTap: () => setState(() => _minRating = r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? BrandTokens.primaryBlue
                        : BrandTokens.bgSoft,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: selected
                          ? BrandTokens.primaryBlue
                          : BrandTokens.borderSoft,
                    ),
                  ),
                  child: Text(
                    label,
                    style: BrandTypography.body(
                      weight: FontWeight.w600,
                      color: selected ? Colors.white : BrandTokens.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Helper gender
          Text(
            'Helper gender',
            style: BrandTypography.body(weight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [(null, 'Any'), ('Male', 'Male'), ('Female', 'Female')]
                .map((opt) {
                  final selected = _helperGender == opt.$1;
                  return GestureDetector(
                    onTap: () => setState(() => _helperGender = opt.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? BrandTokens.primaryBlue
                            : BrandTokens.bgSoft,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: selected
                              ? BrandTokens.primaryBlue
                              : BrandTokens.borderSoft,
                        ),
                      ),
                      child: Text(
                        opt.$2,
                        style: BrandTypography.body(
                          weight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : BrandTokens.textPrimary,
                        ),
                      ),
                    ),
                  );
                })
                .toList(),
          ),
          const SizedBox(height: 24),

          PrimaryGradientButton(
            label: 'Apply filters',
            icon: Icons.check_rounded,
            onPressed: () {
              Navigator.pop(context);
              widget.onApply(
                widget.params.copyWith(
                  sortBy: _sortBy,
                  sortOrder: _sortOrder,
                  minRating: _minRating,
                  maxPrice: _maxPrice,
                  helperGender: _helperGender,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OrderToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _OrderToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ['Asc', 'Desc'].map((v) {
        final selected = value == v;
        return GestureDetector(
          onTap: () => onChanged(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: selected ? BrandTokens.borderTinted : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? BrandTokens.primaryBlue
                    : BrandTokens.borderSoft,
              ),
            ),
            child: Text(
              v == 'Asc' ? '↑ Asc' : '↓ Desc',
              style: BrandTypography.caption(
                weight: FontWeight.w600,
                color: selected
                    ? BrandTokens.primaryBlue
                    : BrandTokens.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Search Summary Card ───────────────────────────────────────────────────────

class _SearchSummaryCard extends StatelessWidget {
  final ScheduledSearchParams params;
  const _SearchSummaryCard({required this.params});

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatDate(params.requestedDate);
    final hours = params.durationInMinutes ~/ 60;
    final minutes = params.durationInMinutes % 60;
    final durationLabel = minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BrandTokens.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_city_rounded,
                color: BrandTokens.primaryBlue,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  params.destinationCity,
                  style: BrandTypography.title(weight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (params.pickupLocationName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.my_location_rounded,
                  color: BrandTokens.textSecondary,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'From: ${params.pickupLocationName}',
                    style: BrandTypography.caption(
                      color: BrandTokens.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(icon: Icons.event_rounded, text: dateLabel),
              _Chip(
                icon: Icons.schedule_rounded,
                text: params.startTime.substring(0, 5),
              ),
              _Chip(icon: Icons.hourglass_top_rounded, text: durationLabel),
              _Chip(
                icon: Icons.translate_rounded,
                text: params.requestedLanguage.toUpperCase(),
              ),
              if (params.requiresCar)
                const _Chip(icon: Icons.directions_car_rounded, text: 'Car'),
              _Chip(
                icon: Icons.group_rounded,
                text:
                    '${params.travelersCount} traveler${params.travelersCount == 1 ? '' : 's'}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Chip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: BrandTokens.bgSoft,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: BrandTokens.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: BrandTokens.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: BrandTypography.caption(color: BrandTokens.textPrimary),
          ),
        ],
      ),
    );
  }
}

// ── Helper Card ───────────────────────────────────────────────────────────────

class _HelperCard extends StatelessWidget {
  final HelperBookingEntity helper;
  final VoidCallback onTap;

  const _HelperCard({required this.helper, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final price = helper.estimatedPrice;
    final priceLabel = price == null ? null : '${price.toStringAsFixed(0)} EGP';
    final distKm = helper.estimatedDistanceKm;
    final reasons = (helper.suitabilityReasons ?? const <String>[])
        .where((r) => r.trim().isNotEmpty)
        .take(3)
        .toList();

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: BrandTokens.surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: BrandTokens.borderSoft),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _Avatar(url: helper.profileImageUrl, name: helper.name),
                if (helper.matchScore != null)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: _MatchScoreBadge(score: helper.matchScore!),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          helper.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BrandTypography.title(weight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RatingPill(
                        rating: helper.rating,
                        trips: helper.completedTrips,
                      ),
                    ],
                  ),
                  if (reasons.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [for (final r in reasons) _ReasonChip(text: r)],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (helper.languages.isNotEmpty)
                        _Tag(
                          icon: Icons.translate_rounded,
                          text: helper.languages.take(3).join(' / '),
                        ),
                      if (helper.car != null)
                        const _Tag(
                          icon: Icons.directions_car_rounded,
                          text: 'Has car',
                        ),
                      if (helper.experienceYears > 0)
                        _Tag(
                          icon: Icons.workspace_premium_rounded,
                          text: '${helper.experienceYears}y exp',
                        ),
                      if (distKm != null)
                        _Tag(
                          icon: Icons.route_rounded,
                          text: '${distKm.toStringAsFixed(1)} km',
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (priceLabel != null) ...[
                        Text(
                          priceLabel,
                          style: BrandTypography.title(
                            weight: FontWeight.w700,
                            color: BrandTokens.primaryBlue,
                          ),
                        ),
                        Text(
                          '  est.',
                          style: BrandTypography.caption(
                            color: BrandTokens.textMuted,
                          ),
                        ),
                      ],
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: BrandTokens.textMuted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String name;
  const _Avatar({required this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
    if (url == null || url!.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: BrandTokens.borderTinted,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: BrandTypography.title(
            weight: FontWeight.w700,
            color: BrandTokens.primaryBlue,
          ),
        ),
      );
    }
    return ClipOval(
      child: Image.network(
        url!,
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
    );
  }
}

class _RatingPill extends StatelessWidget {
  final double rating;
  final int trips;
  const _RatingPill({required this.rating, required this.trips});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: BrandTokens.accentAmberSoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFB45309), size: 14),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: BrandTypography.caption(
              color: BrandTokens.accentAmberText,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Container(width: 1, height: 10, color: BrandTokens.accentAmberBorder),
          const SizedBox(width: 6),
          Text(
            '$trips trips',
            style: BrandTypography.caption(color: BrandTokens.accentAmberText),
          ),
        ],
      ),
    );
  }
}

class _MatchScoreBadge extends StatelessWidget {
  final int score;
  const _MatchScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final clamped = score.clamp(0, 100);
    final Color bg;
    final Color fg;
    if (clamped >= 80) {
      bg = BrandTokens.successGreen;
      fg = Colors.white;
    } else if (clamped >= 60) {
      bg = BrandTokens.accentAmberSoft;
      fg = BrandTokens.accentAmberText;
    } else {
      bg = BrandTokens.bgSoft;
      fg = BrandTokens.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '$clamped%',
        style: BrandTypography.caption(weight: FontWeight.w800, color: fg),
      ),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  final String text;
  const _ReasonChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: BrandTokens.borderTinted,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: BrandTokens.primaryBlue.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 12,
            color: BrandTokens.primaryBlue,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BrandTypography.caption(
                color: BrandTokens.primaryBlue,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Tag({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: BrandTokens.bgSoft,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: BrandTokens.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: BrandTokens.textSecondary),
          const SizedBox(width: 5),
          Text(text, style: BrandTypography.caption()),
        ],
      ),
    );
  }
}

class _LoadingSkeletons extends StatelessWidget {
  const _LoadingSkeletons();

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: BrandTokens.surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: BrandTokens.borderSoft),
        ),
        child: const SkeletonShimmer(
          child: Row(
            children: [
              SkeletonBlock(width: 56, height: 56, radius: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBlock(width: 140, height: 16, radius: 6),
                    SizedBox(height: 10),
                    SkeletonBlock(height: 12, radius: 6),
                    SizedBox(height: 8),
                    SkeletonBlock(width: 200, height: 12, radius: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: BrandTokens.borderTinted,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.search_off_rounded,
              size: 44,
              color: BrandTokens.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No helpers match your trip',
            textAlign: TextAlign.center,
            style: BrandTypography.title(weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different city, slightly later start time, or longer duration to widen your options.',
            textAlign: TextAlign.center,
            style: BrandTypography.body(color: BrandTokens.textSecondary),
          ),
        ],
      ),
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
            'Couldn\'t load helpers',
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
    );
  }
}
