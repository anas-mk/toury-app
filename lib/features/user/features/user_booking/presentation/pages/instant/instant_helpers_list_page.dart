import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/utils/number_format.dart';
import '../../../domain/entities/helper_search_result.dart';
import '../../../domain/entities/instant_search_request.dart';
import '../../cubits/instant_booking_cubit.dart';
import '../../cubits/instant_booking_state.dart';
import '../../widgets/instant/empty_error_state.dart';
import '../../widgets/instant/helper_editorial_card.dart';
import '../../widgets/instant/skeleton.dart';
import 'location_pick_result.dart';

/// Step 4 — list of helpers returned from `POST /user/bookings/instant/search`.
///
/// Pass #6 (2026 editorial redesign):
///   • Light, airy "magazine" layout matching the RAFIQ HTML mockup.
///   • Sticky flat top bar (avatar + wordmark + explore icon).
///   • Big "{N} guides available" headline with animated yellow underline
///     under the count.
///   • Horizontal filter chips (Best Match · Nearest · Top Rated · Lowest
///     Price) — sorting is 100% client-side so we don't need a backend
///     change.
///   • `tune` icon opens a sheet with extra client-side filters
///     (min rating, has car, languages).
///   • Cards animate in with a staggered fade + slide; pressing them
///     scales subtly and triggers haptic feedback.
class InstantHelpersListPage extends StatelessWidget {
  final InstantBookingCubit cubit;
  final InstantSearchRequest searchRequest;
  final LocationPickResult pickup;
  final LocationPickResult destination;
  final int travelers;
  final int durationInMinutes;
  final String? languageCode;
  final bool requiresCar;
  final String? notes;

  const InstantHelpersListPage({
    super.key,
    required this.cubit,
    required this.searchRequest,
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
    return BlocProvider.value(
      value: cubit,
      child: _HelpersListView(
        searchRequest: searchRequest,
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

// ─────────────────────────────────────────────────────────────────────────────
// Sort + filter model
// ─────────────────────────────────────────────────────────────────────────────

enum _SortMode { bestMatch, nearest, topRated, lowestPrice }

class _ExtraFilters {
  final double minRating;
  final bool onlyHasCar;
  final Set<String> languages;
  const _ExtraFilters({
    this.minRating = 0,
    this.onlyHasCar = false,
    this.languages = const {},
  });

  bool get isActive =>
      minRating > 0 || onlyHasCar || languages.isNotEmpty;

  int get activeCount =>
      (minRating > 0 ? 1 : 0) +
      (onlyHasCar ? 1 : 0) +
      (languages.isNotEmpty ? 1 : 0);

  _ExtraFilters copyWith({
    double? minRating,
    bool? onlyHasCar,
    Set<String>? languages,
  }) =>
      _ExtraFilters(
        minRating: minRating ?? this.minRating,
        onlyHasCar: onlyHasCar ?? this.onlyHasCar,
        languages: languages ?? this.languages,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Main view
// ─────────────────────────────────────────────────────────────────────────────

class _HelpersListView extends StatefulWidget {
  final InstantSearchRequest searchRequest;
  final LocationPickResult pickup;
  final LocationPickResult destination;
  final int travelers;
  final int durationInMinutes;
  final String? languageCode;
  final bool requiresCar;
  final String? notes;

  const _HelpersListView({
    required this.searchRequest,
    required this.pickup,
    required this.destination,
    required this.travelers,
    required this.durationInMinutes,
    required this.languageCode,
    required this.requiresCar,
    required this.notes,
  });

  @override
  State<_HelpersListView> createState() => _HelpersListViewState();
}

class _HelpersListViewState extends State<_HelpersListView> {
  _SortMode _sort = _SortMode.bestMatch;
  _ExtraFilters _filters = const _ExtraFilters();

  Map<String, dynamic> _routeExtra(
    BuildContext context,
    HelperSearchResult helper,
  ) {
    return {
      'cubit': context.read<InstantBookingCubit>(),
      'helper': helper,
      'pickup': widget.pickup,
      'destination': widget.destination,
      'travelers': widget.travelers,
      'durationInMinutes': widget.durationInMinutes,
      'languageCode': widget.languageCode,
      'requiresCar': widget.requiresCar,
      'notes': widget.notes,
    };
  }

  /// Open the helper's full profile page (read-only).
  void _onViewProfile(BuildContext context, HelperSearchResult helper) {
    context.push(
      AppRouter.instantHelperProfile.replaceFirst(':id', helper.helperId),
      extra: _routeExtra(context, helper),
    );
  }

  /// Skip the profile and go straight to the booking review (Confirm
  /// Booking) screen — that's what users expect when they tap the
  /// inline "Book Now" CTA on a card.
  void _onBookNow(BuildContext context, HelperSearchResult helper) {
    HapticFeedback.mediumImpact();
    context.push(
      AppRouter.instantBookingReview,
      extra: _routeExtra(context, helper),
    );
  }

  void _retry(BuildContext context) {
    context.read<InstantBookingCubit>().searchHelpers(widget.searchRequest);
  }

  /// Apply both [_sort] and [_filters] to the raw helpers list.
  ///
  /// Sorting is stable: when two helpers tie on the chosen metric we
  /// fall back to backend match score to keep the order deterministic.
  List<HelperSearchResult> _applyFiltersAndSort(
    List<HelperSearchResult> raw,
  ) {
    Iterable<HelperSearchResult> filtered = raw;
    if (_filters.minRating > 0) {
      filtered =
          filtered.where((h) => h.rating >= _filters.minRating);
    }
    if (_filters.onlyHasCar) {
      filtered = filtered.where((h) => h.hasCar);
    }
    if (_filters.languages.isNotEmpty) {
      filtered = filtered.where((h) =>
          h.languages.any((l) => _filters.languages.contains(l.toLowerCase())));
    }
    final list = filtered.toList(growable: false);
    switch (_sort) {
      case _SortMode.bestMatch:
        list.sort((a, b) => b.matchScore.compareTo(a.matchScore));
        break;
      case _SortMode.nearest:
        list.sort((a, b) {
          final ad = a.distanceKm ?? double.infinity;
          final bd = b.distanceKm ?? double.infinity;
          final c = ad.compareTo(bd);
          return c != 0 ? c : b.matchScore.compareTo(a.matchScore);
        });
        break;
      case _SortMode.topRated:
        list.sort((a, b) {
          final c = b.rating.compareTo(a.rating);
          return c != 0 ? c : b.matchScore.compareTo(a.matchScore);
        });
        break;
      case _SortMode.lowestPrice:
        list.sort((a, b) {
          final c = a.estimatedPrice.compareTo(b.estimatedPrice);
          return c != 0 ? c : b.matchScore.compareTo(a.matchScore);
        });
        break;
    }
    return list;
  }

  Future<void> _openFilterSheet(
    BuildContext context,
    Set<String> availableLanguages,
  ) async {
    HapticFeedback.selectionClick();
    final next = await showModalBottomSheet<_ExtraFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        initial: _filters,
        availableLanguages: availableLanguages,
      ),
    );
    if (next != null && mounted) {
      setState(() => _filters = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F4),
      body: BlocBuilder<InstantBookingCubit, InstantBookingState>(
        builder: (context, state) {
          if (state is InstantBookingError) {
            return _ScaffoldFrame(
              filtersActive: _filters.isActive,
              count: 0,
              isLoading: false,
              sort: _sort,
              onSortChanged: null,
              onTuneTap: null,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.55,
                child: ErrorRetryState(
                  message: state.message,
                  onRetry: () => _retry(context),
                ),
              ),
            );
          }

          if (state is InstantBookingHelpersLoaded) {
            final all = state.helpers;
            final list = _applyFiltersAndSort(all);
            final availableLanguages = {
              for (final h in all)
                for (final l in h.languages) l.toLowerCase(),
            };

            return RefreshIndicator(
              onRefresh: () async => _retry(context),
              color: BrandTokens.primaryBlue,
              child: _ScaffoldFrame(
                filtersActive: _filters.isActive,
                filtersBadge: _filters.activeCount,
                count: list.length,
                isLoading: false,
                sort: _sort,
                onSortChanged: (m) {
                  HapticFeedback.selectionClick();
                  setState(() => _sort = m);
                },
                onTuneTap: () => _openFilterSheet(context, availableLanguages),
                child: list.isEmpty
                    ? _EmptyAfterFilters(
                        rawCount: all.length,
                        onClearFilters: _filters.isActive
                            ? () => setState(
                                () => _filters = const _ExtraFilters())
                            : null,
                        onEditSearch: () => context.pop(),
                      )
                    : _AnimatedHelpersList(
                        helpers: list,
                        // The key changes whenever the visible
                        // permutation changes, so the list re-runs
                        // its staggered enter animation.
                        listKey: ValueKey(
                            '$_sort-${_filters.activeCount}-${list.length}'),
                        onView: (h) => _onViewProfile(context, h),
                        onBook: (h) => _onBookNow(context, h),
                      ),
              ),
            );
          }

          // Loading / Initial → editorial skeleton + ranking warmup.
          return _ScaffoldFrame(
            filtersActive: false,
            count: 0,
            isLoading: true,
            sort: _sort,
            onSortChanged: null,
            onTuneTap: null,
            child: const _LoadingBlock(),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scaffold frame (top bar + sticky header + filter chips + child)
// ─────────────────────────────────────────────────────────────────────────────

class _ScaffoldFrame extends StatelessWidget {
  final int count;
  final bool isLoading;
  final _SortMode sort;
  final ValueChanged<_SortMode>? onSortChanged;
  final VoidCallback? onTuneTap;
  final bool filtersActive;
  final int filtersBadge;
  final Widget child;

  const _ScaffoldFrame({
    required this.count,
    required this.isLoading,
    required this.sort,
    required this.onSortChanged,
    required this.onTuneTap,
    required this.filtersActive,
    this.filtersBadge = 0,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Sticky flat top bar. Using `SliverAppBar` (instead of a
        // hand-rolled persistent header) so Flutter handles all the
        // layoutExtent / paintExtent math correctly — a custom delegate
        // is fragile when the body is scrolled into the bar.
        SliverAppBar(
          pinned: true,
          floating: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: const Color(0xFFFAF8F4),
          surfaceTintColor: const Color(0xFFFAF8F4),
          automaticallyImplyLeading: false,
          centerTitle: false,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          toolbarHeight: 64,
          titleSpacing: 0,
          title: const _TopBarContent(),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(24, AppTheme.spaceLG, 24, 16),
            child: _CountHeader(
              count: count,
              isLoading: isLoading,
              filtersActive: filtersActive,
              filtersBadge: filtersBadge,
              onTuneTap: onTuneTap,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _FilterChipsRow(
            sort: sort,
            onChanged: onSortChanged,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
          sliver: SliverToBoxAdapter(child: child),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky top bar
// ─────────────────────────────────────────────────────────────────────────────

/// Inner row used as the title of the [SliverAppBar]. Kept as a
/// stateless widget so the AppBar can reuse it across rebuilds.
class _TopBarContent extends StatelessWidget {
  const _TopBarContent();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BackPill(),
          Text(
            BrandTokens.wordmark,
            style: BrandTokens.heading(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: BrandTokens.primaryBlue,
              letterSpacing: -1.0,
            ),
          ),
          _CompassButton(),
        ],
      ),
    );
  }
}

class _BackPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          context.pop();
        },
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFEFECF5),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.arrow_back_rounded,
            color: BrandTokens.primaryBlue,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _CompassButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          // The "explore" icon in the mockup is decorative. We wire
          // it to scroll back to the top of the list so it feels
          // alive instead of being a dead button — handy on long
          // result lists.
          final ctrl = PrimaryScrollController.maybeOf(context);
          if (ctrl != null && ctrl.hasClients) {
            ctrl.animateTo(
              0,
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutCubic,
            );
          }
        },
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: const Icon(
            Icons.explore_outlined,
            color: BrandTokens.primaryBlue,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Big count headline + tune button
// ─────────────────────────────────────────────────────────────────────────────

class _CountHeader extends StatelessWidget {
  final int count;
  final bool isLoading;
  final bool filtersActive;
  final int filtersBadge;
  final VoidCallback? onTuneTap;

  const _CountHeader({
    required this.count,
    required this.isLoading,
    required this.filtersActive,
    required this.filtersBadge,
    required this.onTuneTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: DefaultTextStyle.merge(
            style: BrandTokens.heading(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: BrandTokens.textPrimary,
              height: 1.15,
              letterSpacing: -0.5,
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _AnimatedCount(value: count, isLoading: isLoading),
                const SizedBox(width: 10),
                Text(
                  count == 1 ? 'guide available' : 'guides available',
                  style: BrandTokens.heading(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: BrandTokens.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        _TuneButton(
          onTap: onTuneTap,
          activeBadge: filtersActive ? filtersBadge : 0,
        ),
      ],
    );
  }
}

/// Big bold count with an animated yellow underline that grows from
/// 0 → full width on first appearance and re-runs whenever the value
/// changes (e.g. user toggles a filter). Adds a subtle "tick" animation
/// on the digit itself when it changes.
class _AnimatedCount extends StatelessWidget {
  final int value;
  final bool isLoading;
  const _AnimatedCount({required this.value, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final shown = isLoading ? '—' : context.localizeNumber(value);
    return TweenAnimationBuilder<double>(
      key: ValueKey('count-$shown'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 8),
                child: Opacity(
                  opacity: t,
                  child: Text(
                    shown,
                    style: BrandTokens.heading(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: BrandTokens.textPrimary,
                      height: 1.0,
                      letterSpacing: -1.2,
                    ),
                  ),
                ),
              ),
            ),
            // Underline accent (amber) — grows from left.
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FractionallySizedBox(
                widthFactor: t,
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFE9331),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TuneButton extends StatelessWidget {
  final VoidCallback? onTap;
  final int activeBadge;
  const _TuneButton({required this.onTap, required this.activeBadge});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeBadge > 0
                    ? BrandTokens.primaryBlue.withValues(alpha: 0.08)
                    : Colors.transparent,
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 22,
                color: activeBadge > 0
                    ? BrandTokens.primaryBlue
                    : BrandTokens.textSecondary,
              ),
            ),
          ),
        ),
        if (activeBadge > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFE9331),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFFFAF8F4), width: 2),
              ),
              child: Text(
                '$activeBadge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Horizontal filter chips
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChipsRow extends StatelessWidget {
  final _SortMode sort;
  final ValueChanged<_SortMode>? onChanged;
  const _FilterChipsRow({required this.sort, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final disabled = onChanged == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (final entry in const [
              MapEntry(_SortMode.bestMatch, 'Best Match'),
              MapEntry(_SortMode.nearest, 'Nearest'),
              MapEntry(_SortMode.topRated, 'Top Rated'),
              MapEntry(_SortMode.lowestPrice, 'Lowest Price'),
            ])
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _SortChip(
                  label: entry.value,
                  selected: sort == entry.key,
                  onTap: disabled ? null : () => onChanged!(entry.key),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? BrandTokens.primaryBlue
        : BrandTokens.surfaceWhite;
    final fg = selected
        ? Colors.white
        : BrandTokens.textSecondary;
    final border = selected
        ? BrandTokens.primaryBlue
        : const Color(0xFFE8E4DF);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(40),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: border, width: 1),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color:
                          BrandTokens.primaryBlue.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: fg,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated helpers list (staggered fade + slide on every re-key)
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedHelpersList extends StatelessWidget {
  final List<HelperSearchResult> helpers;
  final Key listKey;
  final ValueChanged<HelperSearchResult> onView;
  final ValueChanged<HelperSearchResult> onBook;

  const _AnimatedHelpersList({
    required this.helpers,
    required this.listKey,
    required this.onView,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: Column(
        key: listKey,
        children: [
          for (var i = 0; i < helpers.length; i++)
            _StaggeredEntry(
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: HelperEditorialCard(
                  helper: helpers[i],
                  onView: () => onView(helpers[i]),
                  onBook: () => onBook(helpers[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Fades a card up and into view with a per-index delay so a freshly
/// rendered list (or a re-sorted one, courtesy of the parent's `key`)
/// animates in as a staggered cascade rather than all at once.
class _StaggeredEntry extends StatefulWidget {
  final int index;
  final Widget child;
  const _StaggeredEntry({required this.index, required this.child});

  @override
  State<_StaggeredEntry> createState() => _StaggeredEntryState();
}

class _StaggeredEntryState extends State<_StaggeredEntry> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    final delayMs = (widget.index * 70).clamp(0, 700);
    Future<void>.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) setState(() => _show = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _show ? Offset.zero : const Offset(0, 0.12),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _show ? 1 : 0,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// States
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: BrandTokens.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: BrandTokens.ctaBlueGlow,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: BrandTokens.accentAmber,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: BrandTokens.primaryBlue,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Searching helpers',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ranking by trust, distance, language and price.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < 4; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: HelperCardSkeleton(),
          ),
      ],
    );
  }
}

class _EmptyAfterFilters extends StatelessWidget {
  final int rawCount;
  final VoidCallback? onClearFilters;
  final VoidCallback onEditSearch;
  const _EmptyAfterFilters({
    required this.rawCount,
    required this.onClearFilters,
    required this.onEditSearch,
  });

  @override
  Widget build(BuildContext context) {
    final usingFilters = onClearFilters != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: EmptyState(
        icon: usingFilters
            ? Icons.filter_alt_off_rounded
            : Icons.search_off_rounded,
        title: usingFilters
            ? 'No matches with these filters'
            : 'No helpers nearby',
        message: usingFilters
            ? 'Clear your filters to see all $rawCount available guides.'
            : 'Try widening duration, lowering travelers count, or removing the car requirement.',
        actionLabel: usingFilters ? 'Clear filters' : 'Edit search',
        onAction: usingFilters ? onClearFilters : onEditSearch,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter sheet (min rating + has-car + languages)
// ─────────────────────────────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final _ExtraFilters initial;
  final Set<String> availableLanguages;
  const _FilterSheet({
    required this.initial,
    required this.availableLanguages,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late double _minRating;
  late bool _onlyHasCar;
  late Set<String> _languages;

  @override
  void initState() {
    super.initState();
    _minRating = widget.initial.minRating;
    _onlyHasCar = widget.initial.onlyHasCar;
    _languages = {...widget.initial.languages};
  }

  void _reset() {
    HapticFeedback.selectionClick();
    setState(() {
      _minRating = 0;
      _onlyHasCar = false;
      _languages = {};
    });
  }

  void _apply() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(_ExtraFilters(
      minRating: _minRating,
      onlyHasCar: _onlyHasCar,
      languages: _languages,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final langs = widget.availableLanguages.toList()..sort();
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: BrandTokens.surfaceWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: BrandTokens.borderSoft,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filters',
                      style: BrandTokens.heading(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: BrandTokens.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _reset,
                    style: TextButton.styleFrom(
                      foregroundColor: BrandTokens.textSecondary,
                    ),
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE8E4DF)),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                children: [
                  _SectionLabel('MINIMUM RATING'),
                  const SizedBox(height: 12),
                  _RatingPills(
                    selected: _minRating,
                    onChanged: (v) => setState(() => _minRating = v),
                  ),
                  const SizedBox(height: 28),
                  _SectionLabel('VEHICLE'),
                  const SizedBox(height: 12),
                  _ToggleTile(
                    icon: Icons.directions_car_rounded,
                    title: 'Has a car',
                    subtitle: 'Only show guides with a vehicle',
                    value: _onlyHasCar,
                    onChanged: (v) => setState(() => _onlyHasCar = v),
                  ),
                  if (langs.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _SectionLabel('LANGUAGES'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final lang in langs)
                          _LangChip(
                            label: lang.toUpperCase(),
                            selected: _languages.contains(lang),
                            onTap: () => setState(() {
                              if (_languages.contains(lang)) {
                                _languages.remove(lang);
                              } else {
                                _languages.add(lang);
                              }
                            }),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Apply CTA.
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: Material(
                    color: BrandTokens.primaryBlue,
                    borderRadius: BorderRadius.circular(40),
                    child: InkWell(
                      onTap: _apply,
                      borderRadius: BorderRadius.circular(40),
                      child: const Center(
                        child: Text(
                          'Show results',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: BrandTokens.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _RatingPills extends StatelessWidget {
  final double selected;
  final ValueChanged<double> onChanged;
  const _RatingPills({required this.selected, required this.onChanged});

  static const _options = [0.0, 4.0, 4.5, 4.8];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in _options)
          _RatingPill(
            label: v == 0 ? 'Any' : '★ ${v.toStringAsFixed(v == 4.0 ? 0 : 1)}+',
            selected: selected == v,
            onTap: () => onChanged(v),
          ),
      ],
    );
  }
}

class _RatingPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RatingPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(40),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? BrandTokens.primaryBlue
                : BrandTokens.surfaceWhite,
            border: Border.all(
              color: selected
                  ? BrandTokens.primaryBlue
                  : const Color(0xFFE8E4DF),
            ),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : BrandTokens.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: BrandTokens.primaryBlue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: BrandTokens.primaryBlue),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: BrandTokens.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: BrandTokens.primaryBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(40),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? BrandTokens.primaryBlue.withValues(alpha: 0.10)
                : BrandTokens.surfaceWhite,
            border: Border.all(
              color: selected
                  ? BrandTokens.primaryBlue
                  : const Color(0xFFE8E4DF),
            ),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: BrandTokens.primaryBlue,
                  ),
                ),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? BrandTokens.primaryBlue
                      : BrandTokens.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
