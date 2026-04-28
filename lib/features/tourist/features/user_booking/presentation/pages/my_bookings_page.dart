import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/services/realtime/app_realtime_cubit.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/theme/brand_typography.dart';
import '../../../../../../core/widgets/app_network_image.dart';
import '../../../../../../core/widgets/booking_status_chip.dart';
import '../../domain/entities/booking_detail_entity.dart';
import '../cubits/my_bookings_cubit.dart';
import '../cubits/my_bookings_state.dart';
import 'scheduled_trip_details_page.dart';

/// Phase 2 redesign — Bookings History.
///
/// Visual rules from the brief:
///   • Group by month (Booking.com style).
///   • Each row: helper avatar, date, status badge, single price, duration.
///   • Pull-to-refresh, brand shimmer skeletons, empty state.
///   • All state-management bindings are preserved byte-identical
///     (`MyBookingsCubit.getBookings`, `refreshBookings`, route names).
class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  MyBookingsCubit? _registeredCubit;

  @override
  void dispose() {
    final c = _registeredCubit;
    if (c != null) {
      sl<AppRealtimeCubit>().unregisterMyBookings(c);
      _registeredCubit = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return BlocProvider(
      create: (_) {
        final cubit = sl<MyBookingsCubit>()..getBookings();
        _registeredCubit = cubit;
        sl<AppRealtimeCubit>().registerMyBookings(cubit);
        return cubit;
      },
      child: Scaffold(
        backgroundColor: BrandTokens.bgSoft,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _BookingsHeader(title: loc.translate('trips')),
              Expanded(
                child: BlocBuilder<MyBookingsCubit, MyBookingsState>(
                  builder: (context, state) {
                    if (state is MyBookingsLoading ||
                        state is MyBookingsInitial) {
                      return const _BookingsSkeleton();
                    }
                    if (state is MyBookingsError) {
                      return _BookingsError(
                        message: state.message,
                        onRetry: () => context
                            .read<MyBookingsCubit>()
                            .refreshBookings(),
                      );
                    }
                    if (state is MyBookingsLoaded) {
                      if (state.bookings.isEmpty) {
                        return RefreshIndicator.adaptive(
                          color: BrandTokens.primaryBlue,
                          onRefresh: () => context
                              .read<MyBookingsCubit>()
                              .refreshBookings(),
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            children: [_BookingsEmpty(loc: loc)],
                          ),
                        );
                      }
                      return RefreshIndicator.adaptive(
                        color: BrandTokens.primaryBlue,
                        onRefresh: () => context
                            .read<MyBookingsCubit>()
                            .refreshBookings(),
                        child: _BookingsList(bookings: state.bookings),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
//  HEADER
// ============================================================================

class _BookingsHeader extends StatelessWidget {
  final String title;
  const _BookingsHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: BrandTypography.headline()),
                const SizedBox(height: 2),
                Text(
                  'Your travel history with RAFIQ',
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

// ============================================================================
//  LIST WITH MONTH GROUPING
// ============================================================================

class _BookingsList extends StatelessWidget {
  final List<BookingDetailEntity> bookings;
  const _BookingsList({required this.bookings});

  @override
  Widget build(BuildContext context) {
    final groups = _groupByMonth(bookings);

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      itemCount: groups.length,
      itemBuilder: (context, i) {
        final g = groups[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 4 : 18, bottom: 10),
              child: Text(
                g.label,
                style: BrandTypography.overline(
                  color: BrandTokens.textSecondary,
                ),
              ),
            ),
            for (var j = 0; j < g.items.length; j++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: j == g.items.length - 1 ? 0 : 10,
                ),
                child: _BookingRow(booking: g.items[j]),
              ),
          ],
        );
      },
    );
  }

  static List<_MonthGroup> _groupByMonth(List<BookingDetailEntity> items) {
    final fmtKey = DateFormat('yyyy-MM');
    final fmtLabel = DateFormat('MMMM yyyy');
    final now = DateTime.now();
    final thisMonth = fmtKey.format(now);

    final sorted = [...items]
      ..sort((a, b) => b.requestedDate.compareTo(a.requestedDate));

    final map = <String, List<BookingDetailEntity>>{};
    for (final b in sorted) {
      final key = fmtKey.format(b.requestedDate.toLocal());
      map.putIfAbsent(key, () => []).add(b);
    }

    return map.entries.map((e) {
      final firstDate = e.value.first.requestedDate.toLocal();
      final label = e.key == thisMonth
          ? 'THIS MONTH'
          : fmtLabel.format(firstDate).toUpperCase();
      return _MonthGroup(label: label, items: e.value);
    }).toList();
  }
}

class _MonthGroup {
  final String label;
  final List<BookingDetailEntity> items;
  const _MonthGroup({required this.label, required this.items});
}

// ============================================================================
//  ROW (Booking.com info hierarchy)
// ============================================================================

class _BookingRow extends StatelessWidget {
  final BookingDetailEntity booking;
  const _BookingRow({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: BrandTokens.surfaceWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: BrandTokens.cardShadow,
            border: Border.all(
              color: BrandTokens.borderSoft.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(booking: booking),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            'Trip to ${booking.destinationName ?? booking.destinationCity}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BrandTypography.title(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        BookingStatusChip(status: booking.status, dense: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.helper?.name ?? 'No helper assigned yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BrandTypography.caption(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: BrandTokens.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('EEE, MMM d')
                              .format(booking.requestedDate.toLocal()),
                          style: BrandTypography.caption(),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: BrandTokens.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: BrandTokens.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(booking.durationInMinutes),
                          style: BrandTypography.caption(),
                        ),
                        const Spacer(),
                        _PriceLabel(booking: booking),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    HapticFeedback.selectionClick();
    if (booking.type == BookingType.scheduled) {
      final trip = ScheduledTripEntity(
        helperId: booking.helper?.id ?? '',
        destinationCity: booking.destinationCity,
        requestedDate: booking.requestedDate,
        startTime: booking.startTime ?? '09:00',
        durationInMinutes: booking.durationInMinutes,
        requestedLanguage: 'English',
        requiresCar: false,
        travelersCount: 1,
        meetingPointType: 'Standard Pickup',
        pickupLocationName:
            booking.pickupLocationName ?? booking.destinationCity,
        pickupLatitude: booking.pickupLatitude ?? 0.0,
        pickupLongitude: booking.pickupLongitude ?? 0.0,
        notes: booking.notes,
      );
      context.pushNamed('scheduled-trip-details', extra: {'trip': trip});
    } else {
      context.pushNamed(
        'booking-details',
        pathParameters: {'id': booking.id},
        extra: {'booking': booking},
      );
    }
  }

  static String _formatDuration(int minutes) {
    if (minutes <= 0) return '--';
    if (minutes < 60) return '${minutes}m';
    if (minutes % 60 == 0) return '${minutes ~/ 60}h';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }
}

class _Avatar extends StatelessWidget {
  final BookingDetailEntity booking;
  const _Avatar({required this.booking});

  @override
  Widget build(BuildContext context) {
    final url = booking.helper?.profileImageUrl;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: BrandTokens.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: BrandTokens.shadowSoft,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? AppNetworkImage(
                imageUrl: url,
                width: 48,
                height: 48,
                borderRadius: 24,
              )
            : Container(
                color: Colors.white,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.person_rounded,
                  color: BrandTokens.primaryBlue,
                  size: 24,
                ),
              ),
      ),
    );
  }
}

class _PriceLabel extends StatelessWidget {
  final BookingDetailEntity booking;
  const _PriceLabel({required this.booking});

  @override
  Widget build(BuildContext context) {
    final currency = booking.currency ?? 'EGP';
    final price = booking.finalPrice ?? booking.estimatedPrice;
    if (price == null) {
      return Text(
        '--',
        style: BrandTypography.caption(color: BrandTokens.textMuted),
      );
    }
    final isFinal = booking.finalPrice != null;
    return Text(
      '${isFinal ? '' : '~ '}${price.toStringAsFixed(0)} $currency',
      style: BrandTokens.numeric(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: isFinal
            ? BrandTokens.accentAmberText
            : BrandTokens.textSecondary,
      ),
    );
  }
}

// ============================================================================
//  EMPTY / ERROR / SKELETON
// ============================================================================

class _BookingsEmpty extends StatelessWidget {
  final AppLocalizations loc;
  const _BookingsEmpty({required this.loc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 32),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: BrandTokens.amberGradient,
              shape: BoxShape.circle,
              boxShadow: BrandTokens.ctaAmberGlow,
            ),
            child: const Icon(
              Icons.luggage_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            loc.translate('no_bookings_yet'),
            textAlign: TextAlign.center,
            style: BrandTypography.title(),
          ),
          const SizedBox(height: 6),
          Text(
            'Your trips will appear here once you book your first helper.',
            textAlign: TextAlign.center,
            style: BrandTypography.caption(),
          ),
        ],
      ),
    );
  }
}

class _BookingsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _BookingsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: BrandTokens.dangerSos,
            ),
            const SizedBox(height: 12),
            Text(
              'Could not load trips',
              style: BrandTypography.title(),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: BrandTypography.caption(),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onRetry();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandTokens.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingsSkeleton extends StatelessWidget {
  const _BookingsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        for (var i = 0; i < 5; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Shimmer.fromColors(
              baseColor: const Color(0xFFE7EAF6),
              highlightColor: const Color(0xFFF6F8FE),
              period: const Duration(milliseconds: 1400),
              child: Container(
                height: 96,
                decoration: BoxDecoration(
                  color: BrandTokens.surfaceWhite,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
      ],
    );
  }
}