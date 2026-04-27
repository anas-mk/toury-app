import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/utils/responsive.dart';
import '../../../../../../../core/widgets/hero_header.dart';
import '../../../domain/entities/alternatives_response.dart';
import '../../../domain/entities/booking_detail.dart';
import '../../../domain/entities/helper_search_result.dart';
import '../../cubits/instant_booking_cubit.dart';
import '../../widgets/instant/empty_error_state.dart';
import '../../widgets/instant/helper_suitability_card.dart';
import 'location_pick_result.dart';
import 'location_picker_page.dart';

/// Step 8 — shown when the original helper declined / expired or the
/// system asked the user to pick again.
class BookingAlternativesPage extends StatefulWidget {
  final InstantBookingCubit cubit;
  final BookingDetail booking;
  final AlternativesResponse alternatives;

  const BookingAlternativesPage({
    super.key,
    required this.cubit,
    required this.booking,
    required this.alternatives,
  });

  @override
  State<BookingAlternativesPage> createState() =>
      _BookingAlternativesPageState();
}

class _BookingAlternativesPageState extends State<BookingAlternativesPage> {
  /// User-supplied destination override (when the booking detail is missing it).
  LocationPickResult? _destinationOverride;

  bool get _hasDestinationCoords {
    if (_destinationOverride != null) return true;
    return widget.booking.destinationLatitude != null &&
        widget.booking.destinationLongitude != null;
  }

  Future<void> _pickDestination() async {
    final result = await Navigator.of(context).push<LocationPickResult>(
      MaterialPageRoute(
        builder: (_) => const LocationPickerPage(
          title: 'Destination',
          isPickup: false,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _destinationOverride = result);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Destination updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final empty = widget.alternatives.alternativeHelpers.isEmpty;
    return BlocProvider.value(
      value: widget.cubit,
      child: Scaffold(
        backgroundColor: BrandTokens.bgSoft,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPersistentHeader(
              pinned: false,
              delegate: HeroSliverHeader(
                title: 'Pick another helper',
                subtitle: 'We found a few helpers who could take this trip',
                leadingIcon: Icons.swap_horiz_rounded,
                gradient: const [
                  AppColor.warningColor,
                  AppColor.errorColor,
                ],
                height: r.pick(compact: 180.0, phone: 200.0, tablet: 220.0),
              ),
            ),
            if (empty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.person_search_rounded,
                  title: 'No helpers available',
                  message: widget.alternatives.message,
                  actionLabel: 'Back to home',
                  onAction: () => context.go(AppRouter.bookingHome),
                ),
              )
            else
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(maxWidth: r.contentMaxWidth),
                    child: Transform.translate(
                      offset: Offset(0,
                          -r.pick(compact: 26.0, phone: 32.0, tablet: 40.0)),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: r.pagePadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Banner(
                              message: widget.alternatives.message,
                              isAutoRetry:
                                  widget.alternatives.autoRetryActive,
                            ),
                            if (!_hasDestinationCoords) ...[
                              SizedBox(height: r.gapSM + 2),
                              _MissingDestinationCard(
                                  onPick: _pickDestination),
                            ],
                            SizedBox(height: r.gap),
                            if (widget.alternatives.assignmentHistory
                                .isNotEmpty) ...[
                              _History(
                                history:
                                    widget.alternatives.assignmentHistory,
                              ),
                              SizedBox(height: r.gap),
                            ],
                            _ListHeader(
                              count: widget.alternatives
                                  .alternativeHelpers.length,
                            ),
                            SizedBox(height: r.gapSM),
                            for (final h in widget
                                .alternatives.alternativeHelpers)
                              Padding(
                                padding: EdgeInsets.only(bottom: r.gapSM + 2),
                                child: Stack(
                                  children: [
                                    HelperSuitabilityCard(
                                      helper: h,
                                      onTap: _hasDestinationCoords
                                          ? () => _onPick(context, h)
                                          : () {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Please re-pick destination on the map',
                                                  ),
                                                ),
                                              );
                                              _pickDestination();
                                            },
                                    ),
                                    if (!_hasDestinationCoords)
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          ignoring: true,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(22),
                                            child: Container(
                                              color: Colors.white
                                                  .withValues(alpha: 0.55),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            SizedBox(height: r.gapXL),
                          ],
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

  void _onPick(BuildContext context, HelperSearchResult helper) {
    final pickup = LocationPickResult(
      name: widget.booking.pickupLocationName,
      address: widget.booking.pickupAddress,
      latitude: widget.booking.pickupLatitude,
      longitude: widget.booking.pickupLongitude,
    );

    LocationPickResult destination;
    if (_destinationOverride != null) {
      destination = _destinationOverride!;
    } else if (widget.booking.destinationLatitude != null &&
        widget.booking.destinationLongitude != null) {
      destination = LocationPickResult(
        name: widget.booking.destinationName ?? 'Destination',
        latitude: widget.booking.destinationLatitude!,
        longitude: widget.booking.destinationLongitude!,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please re-pick destination on the map'),
        ),
      );
      _pickDestination();
      return;
    }

    context.push(
      AppRouter.instantBookingReview,
      extra: {
        'cubit': widget.cubit,
        'helper': helper,
        'pickup': pickup,
        'destination': destination,
        'travelers': widget.booking.travelersCount,
        'durationInMinutes': widget.booking.durationInMinutes,
        'languageCode': widget.booking.requestedLanguage,
        'requiresCar': widget.booking.requiresCar,
        'notes': widget.booking.notes,
      },
    );
  }
}

class _ListHeader extends StatelessWidget {
  final int count;
  const _ListHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return Row(
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
        Expanded(
          child: Text(
            'Available helpers',
            style: BrandTokens.heading(
              fontSize: r.fontTitle,
              fontWeight: FontWeight.w800,
              color: BrandTokens.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: BrandTokens.primaryBlue.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Text(
            '$count',
            style: BrandTokens.numeric(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: BrandTokens.primaryBlue,
            ),
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final String message;
  final bool isAutoRetry;
  const _Banner({required this.message, required this.isAutoRetry});

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return Container(
      padding: EdgeInsets.all(r.gap),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: BrandTokens.borderSoft.withValues(alpha: 0.7),
        ),
        boxShadow: BrandTokens.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  BrandTokens.warningAmber.withValues(alpha: 0.95),
                  BrandTokens.accentAmber,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: BrandTokens.glowAmber,
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
            ),
          ),
          SizedBox(width: r.gapSM + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: BrandTokens.body(
                    fontSize: r.fontBody,
                    fontWeight: FontWeight.w600,
                    color: BrandTokens.textPrimary,
                    height: 1.4,
                  ),
                ),
                if (isAutoRetry) ...[
                  SizedBox(height: r.gapSM),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: BrandTokens.successGreen.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          size: 13,
                          color: BrandTokens.successGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Auto retry active',
                          style: BrandTokens.body(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: BrandTokens.successGreen,
                          ),
                        ),
                      ],
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

class _MissingDestinationCard extends StatelessWidget {
  final VoidCallback onPick;
  const _MissingDestinationCard({required this.onPick});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: AppColor.errorColor.withValues(alpha: 0.06),
        border: Border.all(color: AppColor.errorColor.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_off_rounded,
                color: AppColor.errorColor,
              ),
              const SizedBox(width: AppTheme.spaceSM),
              Expanded(
                child: Text(
                  'Destination missing',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            'We don\'t have coordinates for your destination. Please pick it on the map to continue.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColor.lightTextSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          FilledButton.icon(
            onPressed: onPick,
            style: FilledButton.styleFrom(
              backgroundColor: AppColor.errorColor,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
            icon: const Icon(Icons.map_rounded),
            label: const Text('Re-pick on the map'),
          ),
        ],
      ),
    );
  }
}

class _History extends StatelessWidget {
  final List<AssignmentAttempt> history;
  const _History({required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Row(
            children: [
              const Icon(
                Icons.history_rounded,
                color: AppColor.lightTextSecondary,
              ),
              const SizedBox(width: AppTheme.spaceSM),
              Text(
                'What we tried (${history.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          children: [
            for (final h in history)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '#${h.attemptOrder}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h.helperName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _label(h.responseStatus),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColor.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _icon(h.responseStatus),
                      color: _color(h.responseStatus),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _label(String s) {
    switch (s) {
      case 'Pending':
        return 'Asked';
      case 'Accepted':
        return 'Accepted';
      case 'Declined':
        return 'Declined';
      case 'Expired':
        return 'Did not respond in time';
      default:
        return s;
    }
  }

  IconData _icon(String s) {
    switch (s) {
      case 'Accepted':
        return Icons.check_circle_rounded;
      case 'Declined':
        return Icons.cancel_rounded;
      case 'Expired':
        return Icons.timer_off_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _color(String s) {
    switch (s) {
      case 'Accepted':
        return AppColor.accentColor;
      case 'Declined':
        return AppColor.errorColor;
      case 'Expired':
        return AppColor.warningColor;
      default:
        return AppColor.lightTextSecondary;
    }
  }
}
