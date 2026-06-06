import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/di/injection_container.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/widgets/app_network_image.dart';
import '../../../domain/entities/helper_booking_entity.dart';
import '../../../domain/entities/search_params.dart';
import '../../cubits/search_helpers_cubit.dart';
import '../../cubits/search_helpers_state.dart';
import 'scheduled_search_context.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kNavy = Color(0xFF000668);
const _kBlue = Color(0xFF4851C4);
const _kAmber = Color(0xFFFE9331);
const _kSurface = Color(0xFFFBF8FF);
const _kCard = Color(0xFFFFFFFF);
const _kMuted = Color(0xFF767683);
const _kContainerLow = Color(0xFFF4F2FF);
const _kOutlineVariant = Color(0xFFC6C5D3);

const _kGradient = LinearGradient(
  colors: [_kNavy, _kBlue],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

const _kCardShadow = [
  BoxShadow(
    color: Color(0x121B237E),
    blurRadius: 28,
    offset: Offset(0, 10),
  ),
];

// ── Sort options ──────────────────────────────────────────────────────────────
const _kSortOptions = <(String value, String label)>[
  ('MatchScore', 'Best Match'),
  ('Rating', 'Top Rated'),
  ('Price_Asc', 'Price ↑'),
  ('Price_Desc', 'Price ↓'),
  ('Experience', 'Most Exp.'),
];

// ── Screen ───────────────────────────────────────────────────────────────────

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
  String _activeSortKey = 'MatchScore';
  bool _carFilter = false;
  bool _femaleFilter = false;

  @override
  void initState() {
    super.initState();
    _params = widget.params;
  }

  // ── helpers ─────────────────────────────────────────────────────────────

  String _compactSummary() {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final d = _params.requestedDate;
    final h = _params.durationInMinutes ~/ 60;
    final guests = _params.travelersCount;
    final date = '${d.day} ${months[d.month - 1]}';
    final dur = h == 8 ? 'Full Day' : '${h}h';
    return '${_params.destinationCity}  ·  $date  ·  $dur  ·  $guests pax';
  }

  void _applySort(String key) {
    HapticFeedback.selectionClick();
    setState(() => _activeSortKey = key);
    final (sortBy, sortOrder) = _parseSortKey(key);
    final updated = _params.copyWith(sortBy: sortBy, sortOrder: sortOrder);
    setState(() => _params = updated);
    context.read<SearchHelpersCubit>().searchScheduled(updated);
  }

  (String, String) _parseSortKey(String key) {
    if (key == 'Price_Asc') return ('Price', 'Asc');
    if (key == 'Price_Desc') return ('Price', 'Desc');
    return (key, 'Desc');
  }

  void _applyFilterToggle({bool? car, bool? female}) {
    HapticFeedback.selectionClick();
    setState(() {
      if (car != null) _carFilter = car;
      if (female != null) _femaleFilter = female;
    });
    final updated = _params.copyWith(
      helperGender: _femaleFilter ? 'Female' : null,
    );
    setState(() => _params = updated);
    context.read<SearchHelpersCubit>().searchScheduled(updated);
  }

  Future<void> _onRefresh() async {
    HapticFeedback.selectionClick();
    await context.read<SearchHelpersCubit>().searchScheduled(_params);
  }

  void _showFilterSheet() {
    showModalBottomSheet<ScheduledSearchParams>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        params: _params,
        onApply: (updated) {
          setState(() => _params = updated);
          context.read<SearchHelpersCubit>().searchScheduled(updated);
        },
      ),
    );
  }

  void _openHelperProfile(BuildContext ctx, HelperBookingEntity helper) {
    HapticFeedback.lightImpact();
    ScheduledSearchContext.instance.rememberHelper(
      params: _params,
      helper: helper,
    );
    ctx.push(
      AppRouter.scheduledHelperProfile.replaceFirst(':id', helper.id),
      extra: {'helper': helper, 'params': _params},
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return BlocProvider<SearchHelpersCubit>(
      create: (_) => sl<SearchHelpersCubit>()..searchScheduled(_params),
      child: Builder(
        builder: (ctx) {
          return Scaffold(
            backgroundColor: _kSurface,
            body: Column(
              children: [
                // ── Sticky header ────────────────────────────────────────
                _StickyHeader(
                  topPad: topPad,
                  summary: _compactSummary(),
                  hasActiveFilter: _carFilter ||
                      _femaleFilter ||
                      _params.minRating != null ||
                      _params.helperGender != null,
                  onBack: () => ctx.pop(),
                  onFilter: _showFilterSheet,
                ),

                // ── Scrollable body ──────────────────────────────────────
                Expanded(
                  child: RefreshIndicator(
                    color: _kNavy,
                    onRefresh: _onRefresh,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        // Sort + filter chips
                        SliverToBoxAdapter(
                          child: _SortFilterRow(
                            activeSort: _activeSortKey,
                            carFilter: _carFilter,
                            femaleFilter: _femaleFilter,
                            onSortChanged: _applySort,
                            onCarToggle: () =>
                                _applyFilterToggle(car: !_carFilter),
                            onFemaleToggle: () =>
                                _applyFilterToggle(female: !_femaleFilter),
                          ),
                        ),

                        // Results
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
                              ScheduledSearchContext.instance.rememberResults(
                                params: _params,
                                helpers: state.helpers,
                              );
                              if (state.helpers.isEmpty) {
                                return SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: _EmptyState(
                                    onModify: () => ctx.pop(),
                                  ),
                                );
                              }
                              return SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  20,
                                  8,
                                  20,
                                  24 + bottomPad,
                                ),
                                sliver: SliverList.separated(
                                  itemCount: state.helpers.length + 1,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 14),
                                  itemBuilder: (_, i) {
                                    if (i == 0) {
                                      return _CountBadge(
                                        count: state.availableCount,
                                      );
                                    }
                                    final helper = state.helpers[i - 1];
                                    return _GuideCard(
                                      helper: helper,
                                      onTap: () =>
                                          _openHelperProfile(ctx, helper),
                                    );
                                  },
                                ),
                              );
                            }
                            return const SliverToBoxAdapter(
                              child: SizedBox.shrink(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Sticky header ─────────────────────────────────────────────────────────────

class _StickyHeader extends StatelessWidget {
  final double topPad;
  final String summary;
  final bool hasActiveFilter;
  final VoidCallback onBack;
  final VoidCallback onFilter;

  const _StickyHeader({
    required this.topPad,
    required this.summary,
    required this.hasActiveFilter,
    required this.onBack,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPad + 8, 16, 12),
      decoration: const BoxDecoration(
        color: _kCard,
        boxShadow: [
          BoxShadow(
            color: Color(0x0E1B237E),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: _kSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: _kNavy,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Compact summary chip
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: _kContainerLow,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                summary,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _kBlue,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Filter icon
          GestureDetector(
            onTap: onFilter,
            child: Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: _kSurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: _kNavy,
                    size: 20,
                  ),
                ),
                if (hasActiveFilter)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _kAmber,
                        shape: BoxShape.circle,
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

// ── Sort + filter chips row ───────────────────────────────────────────────────

class _SortFilterRow extends StatelessWidget {
  final String activeSort;
  final bool carFilter;
  final bool femaleFilter;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onCarToggle;
  final VoidCallback onFemaleToggle;

  const _SortFilterRow({
    required this.activeSort,
    required this.carFilter,
    required this.femaleFilter,
    required this.onSortChanged,
    required this.onCarToggle,
    required this.onFemaleToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          // Sort chips
          ..._kSortOptions.map((opt) {
            final selected = activeSort == opt.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
              child: GestureDetector(
                onTap: () => onSortChanged(opt.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                  decoration: BoxDecoration(
                    gradient: selected ? _kGradient : null,
                    color: selected ? null : _kCard,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : _kOutlineVariant.withValues(alpha: 0.5),
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: _kNavy.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      opt.$2,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : _kMuted,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          // With Car toggle
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            child: GestureDetector(
              onTap: onCarToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: carFilter
                      ? _kAmber.withValues(alpha: 0.15)
                      : _kCard,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: carFilter
                        ? _kAmber
                        : _kOutlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_car_rounded,
                      size: 14,
                      color: carFilter ? _kAmber : _kMuted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'With Car',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: carFilter ? _kAmber : _kMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Female Only toggle
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            child: GestureDetector(
              onTap: onFemaleToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: femaleFilter
                      ? _kBlue.withValues(alpha: 0.1)
                      : _kCard,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: femaleFilter
                        ? _kBlue
                        : _kOutlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.female_rounded,
                      size: 14,
                      color: femaleFilter ? _kBlue : _kMuted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Female',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: femaleFilter ? _kBlue : _kMuted,
                      ),
                    ),
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

// ── Count badge ───────────────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$count guide${count == 1 ? '' : 's'} available for your trip',
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _kNavy,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 3,
          width: 80,
          decoration: BoxDecoration(
            gradient: _kGradient,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ── Guide card ────────────────────────────────────────────────────────────────

class _GuideCard extends StatelessWidget {
  final HelperBookingEntity helper;
  final VoidCallback onTap;

  const _GuideCard({required this.helper, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final matchScore = helper.matchScore ?? 0;
    final isTopMatch = matchScore >= 80;
    final price = helper.estimatedPrice;
    final suitability = (helper.suitabilityReasons ?? const <String>[])
        .where((r) => r.trim().isNotEmpty)
        .firstOrNull;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(24),
          boxShadow: _kCardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: avatar + info + match badge ──────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with optional Top Match badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _GuideAvatar(
                        url: helper.profileImageUrl,
                        name: helper.name,
                        size: 68,
                      ),
                      if (isTopMatch)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _kAmber,
                              borderRadius: BorderRadius.circular(99),
                              boxShadow: [
                                BoxShadow(
                                  color: _kAmber.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  size: 10,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'Top Match',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // Name + rating + speciality
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          helper.name,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _kNavy,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: _kAmber,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              helper.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _kNavy,
                              ),
                            ),
                            Text(
                              '  ·  ${helper.completedTrips} trips  ·  ${helper.experienceYears} yrs exp',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                color: _kMuted,
                              ),
                            ),
                          ],
                        ),
                        if (suitability != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            '"$suitability"',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: _kMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Language + car chips ───────────────────────────────────
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...helper.languages.take(3).map(
                        (lang) => _SmallChip(
                          label: lang,
                          color: _kBlue,
                          bg: _kContainerLow,
                        ),
                      ),
                  if (helper.car != null)
                    const _SmallChip(
                      label: '🚗 With Car',
                      color: _kAmber,
                      bg: Color(0xFFFFF4E6),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Divider ────────────────────────────────────────────────
              Container(
                height: 1,
                color: _kOutlineVariant.withValues(alpha: 0.4),
              ),

              const SizedBox(height: 14),

              // ── Price + CTA ────────────────────────────────────────────
              Row(
                children: [
                  if (price != null) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FROM',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: _kMuted,
                          ),
                        ),
                        Text(
                          'EGP ${price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _kNavy,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                  // View Profile CTA
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: _kGradient,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: _kNavy.withValues(alpha: 0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Profile',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Guide avatar ──────────────────────────────────────────────────────────────

class _GuideAvatar extends StatelessWidget {
  final String? url;
  final String name;
  final double size;

  const _GuideAvatar({
    required this.url,
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141B237E),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: url != null
            ? AppNetworkImage(
                imageUrl: url,
                width: size,
                height: size,
                borderRadius: size / 2,
              )
            : Container(
                color: _kContainerLow,
                alignment: Alignment.center,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: _kNavy,
                  ),
                ),
              ),
      ),
    );
  }
}

// ── Small chip ────────────────────────────────────────────────────────────────

class _SmallChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _SmallChip({
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── Filter sheet ──────────────────────────────────────────────────────────────

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
  String? _helperGender;

  static const _sortOptions = <(String, String)>[
    ('MatchScore', 'Best Match'),
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
    _helperGender = widget.params.helperGender;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _kOutlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Row(
            children: [
              const Text(
                'Filter & Sort',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _kNavy,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() {
                  _sortBy = 'MatchScore';
                  _sortOrder = 'Desc';
                  _minRating = null;
                  _helperGender = null;
                }),
                child: const Text(
                  'Reset',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Sort by
          const Text(
            'SORT BY',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: _kMuted,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sortOptions.map((opt) {
              final selected = _sortBy == opt.$1;
              return GestureDetector(
                onTap: () => setState(() => _sortBy = opt.$1),
                child: _FilterChip(label: opt.$2, selected: selected),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          Row(
            children: ['Asc', 'Desc'].map((v) {
              final sel = _sortOrder == v;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _sortOrder = v),
                  child: _FilterChip(
                    label: v == 'Asc' ? '↑ Low to high' : '↓ High to low',
                    selected: sel,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Min rating
          const Text(
            'MINIMUM RATING',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: _kMuted,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [null, 3.0, 4.0, 4.5].map((r) {
              final selected = _minRating == r;
              final label =
                  r == null ? 'Any' : '${r % 1 == 0 ? r.toInt() : r}+ ⭐';
              return GestureDetector(
                onTap: () => setState(() => _minRating = r),
                child: _FilterChip(label: label, selected: selected),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Gender
          const Text(
            'GUIDE GENDER',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: _kMuted,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [(null, 'Any'), ('Male', 'Male ♂'), ('Female', 'Female ♀')]
                .map((opt) {
              final selected = _helperGender == opt.$1;
              return GestureDetector(
                onTap: () => setState(() => _helperGender = opt.$1),
                child: _FilterChip(label: opt.$2, selected: selected),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Apply button
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              widget.onApply(
                widget.params.copyWith(
                  sortBy: _sortBy,
                  sortOrder: _sortOrder,
                  minRating: _minRating,
                  helperGender: _helperGender,
                ),
              );
            },
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: _kGradient,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: _kNavy.withValues(alpha: 0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.check_rounded, color: Colors.white, size: 18),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  const _FilterChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        gradient: selected ? _kGradient : null,
        color: selected ? null : _kContainerLow,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : _kNavy,
        ),
      ),
    );
  }
}

// ── Loading skeletons ─────────────────────────────────────────────────────────

class _LoadingSkeletons extends StatelessWidget {
  const _LoadingSkeletons();

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, __) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final shimmer = Color.lerp(
          const Color(0xFFE8E6F0),
          const Color(0xFFF5F3FF),
          _ctrl.value,
        )!;
        return Container(
          height: 180,
          decoration: BoxDecoration(
            color: shimmer,
            borderRadius: BorderRadius.circular(24),
          ),
        );
      },
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onModify;
  const _EmptyState({required this.onModify});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _kContainerLow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_search_rounded,
              size: 40,
              color: _kBlue,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No guides match your criteria',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _kNavy,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your duration, language, or travel dates.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              color: _kMuted,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onModify,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: _kBlue),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Text(
                'Modify Search',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEBEE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              size: 36,
              color: Color(0xFFE53935),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Could not load guides',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _kNavy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              color: _kMuted,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: _kGradient,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
