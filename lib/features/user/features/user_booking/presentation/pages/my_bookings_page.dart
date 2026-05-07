import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/services/realtime/app_realtime_cubit.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/theme/brand_typography.dart';
import '../../../../../../core/widgets/app_empty_state.dart';
import '../../../../../../core/widgets/app_error_state.dart';
import '../../../../../../core/widgets/app_loading.dart';
import '../../../../../../core/widgets/app_network_image.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/booking_status_chip.dart';
import '../../domain/entities/booking_detail_entity.dart';
import '../cubits/my_bookings_cubit.dart';
import '../cubits/my_bookings_state.dart';

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
    final palette = AppColors.of(context);

    return BlocProvider(
      create: (_) {
        final cubit = sl<MyBookingsCubit>()..getBookings();
        _registeredCubit = cubit;
        sl<AppRealtimeCubit>().registerMyBookings(cubit);
        return cubit;
      },
      child: AppScaffold(
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
                      return const Center(child: AppLoading(fullScreen: false));
                    }
                    if (state is MyBookingsError) {
                      return Center(
                        child: AppErrorState(
                          title: 'Could not load trips',
                          message: state.message,
                          onRetry: () =>
                              context.read<MyBookingsCubit>().refreshBookings(),
                        ),
                      );
                    }
                    if (state is MyBookingsLoaded) {
                      if (state.bookings.isEmpty) {
                        return RefreshIndicator.adaptive(
                          color: palette.primary,
                          onRefresh: () =>
                              context.read<MyBookingsCubit>().refreshBookings(),
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: EdgeInsets.only(
                              top: AppSpacing.xxxl + AppSpacing.lg,
                            ),
                            children: [
                              AppEmptyState(
                                icon: Icons.luggage_rounded,
                                title: loc.translate('no_bookings_yet'),
                                message:
                                    'Your trips will appear here once you '
                                    'book your first helper.',
                              ),
                            ],
                          ),
                        );
                      }
                      return RefreshIndicator.adaptive(
                        color: palette.primary,
                        onRefresh: () =>
                            context.read<MyBookingsCubit>().refreshBookings(),
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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        AppSpacing.sm,
        AppSpacing.pageGutter,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: BrandTypography.headline()),
                const SizedBox(height: AppSpacing.xs),
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
      addAutomaticKeepAlives: false,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        0,
        AppSpacing.pageGutter,
        AppSpacing.xxxl,
      ),
      itemCount: groups.length,
      itemBuilder: (context, i) {
        final g = groups[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: i == 0 ? AppSpacing.xs : AppSpacing.pageGutter,
                bottom: AppSpacing.sm + AppSpacing.xs,
              ),
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
                  bottom: j == g.items.length - 1
                      ? 0
                      : AppSpacing.sm + AppSpacing.xs,
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
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xs),
          decoration: BoxDecoration(
            color: BrandTokens.surfaceWhite,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: BrandTokens.cardShadow,
            border: Border.all(
              color: BrandTokens.borderSoft.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(booking: booking),
              const SizedBox(width: AppSpacing.md),
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
                        const SizedBox(width: AppSpacing.sm),
                        BookingStatusChip(status: booking.status, dense: true),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      booking.helper?.name ?? 'No helper assigned yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BrandTypography.caption(),
                    ),
                    const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: BrandTokens.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          DateFormat(
                            'EEE, MMM d',
                          ).format(booking.requestedDate.toLocal()),
                          style: BrandTypography.caption(),
                        ),
                        const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: BrandTokens.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                        const Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: BrandTokens.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
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
    // Both Instant and Scheduled bookings now share the same unified
    // detail screen (`/booking-details/:id`). The page reads the booking
    // type from the entity and renders the right CTAs.
    context.pushNamed('booking-details', pathParameters: {'id': booking.id});
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
