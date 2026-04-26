import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toury/features/tourist/features/user_booking/presentation/cubits/booking_status_cubit.dart';
import 'package:toury/features/tourist/features/user_booking/presentation/cubits/booking_status_state.dart';
import 'package:toury/features/tourist/features/user_booking/presentation/cubits/my_bookings_cubit.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../user_booking/presentation/cubits/my_bookings_state.dart';
import '../widgets/active_booking_banner.dart';
import '../widgets/recent_booking_card.dart';
import '../widgets/upcoming_trip_preview_card.dart';
import '../../../user_booking/domain/entities/booking_detail_entity.dart';

class TouristHomePage extends StatefulWidget {
  const TouristHomePage({super.key});

  @override
  State<TouristHomePage> createState() => _TouristHomePageState();
}

class _TouristHomePageState extends State<TouristHomePage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<BookingStatusCubit>().startPollingForActive();
          context.read<MyBookingsCubit>().refreshBookings(pageSize: 5);
        },
        child: CustomScrollView(
          slivers: [
            // Header Bar
            SliverAppBar(
              floating: true,
              pinned: true,
              expandedHeight: 70,
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              title: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/account-settings'),
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColor.lightBorder,
                      child: Icon(Icons.person, color: AppColor.primaryColor),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMD),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translate('good_morning'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColor.lightTextSecondary,
                        ),
                      ),
                      Text(
                        'Ahmed 👋', // Should be dynamic from user profile
                        style: theme.textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () {},
                ),
                const SizedBox(width: AppTheme.spaceMD),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppTheme.spaceMD),

                  // Active Booking Banner
                  BlocBuilder<BookingStatusCubit, BookingStatusState>(
                    builder: (context, state) {
                      if (state is BookingStatusActive) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppTheme.spaceLG),
                          child: ActiveBookingBanner(booking: state.booking),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Upcoming Scheduled Trip Preview Section
                  Row(
                    children: [
                      Text(
                        'Upcoming Trip',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  BlocBuilder<MyBookingsCubit, MyBookingsState>(
                    builder: (context, state) {
                      if (state is MyBookingsLoading) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: AppTheme.spaceLG),
                          child: UpcomingTripSkeleton(),
                        );
                      }
                      if (state is MyBookingsLoaded) {
                        final upcomingBookings = state.bookings.where((b) => 
                          b.type == BookingType.scheduled && 
                          (b.status == BookingStatus.acceptedByHelper || b.status == BookingStatus.upcoming || b.status == BookingStatus.pendingHelperResponse)
                        ).toList();
                        
                        if (upcomingBookings.isNotEmpty) {
                          // Sort by date (closest first)
                          upcomingBookings.sort((a, b) => a.requestedDate.compareTo(b.requestedDate));
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppTheme.spaceLG),
                            child: UpcomingTripPreviewCard(booking: upcomingBookings.first),
                          );
                        }
                      }
                      return const Padding(
                        padding: EdgeInsets.only(bottom: AppTheme.spaceLG),
                        child: UpcomingTripEmptyState(),
                      );
                    },
                  ),

                  // Hero CTA - Book Now
                  _buildBookNowHero(context, loc),

                  const SizedBox(height: AppTheme.spaceXL),

                  // Quick Actions Row
                  _buildQuickActions(context, loc),

                  const SizedBox(height: AppTheme.spaceXL),

                  // Recent Bookings Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.translate('recent_bookings'),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRouter.myBookings),
                        child: Text(loc.translate('view_all')),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceMD),

                  BlocBuilder<MyBookingsCubit, MyBookingsState>(
                    builder: (context, state) {
                      if (state is MyBookingsLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is MyBookingsLoaded) {
                        if (state.bookings.isEmpty) {
                          return _buildEmptyState(loc);
                        }
                        return SizedBox(
                          height: 180,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: state.bookings.length,
                            separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spaceMD),
                            itemBuilder: (context, index) {
                              return RecentBookingCard(booking: state.bookings[index]);
                            },
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  const SizedBox(height: AppTheme.space2XL),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookNowHero(BuildContext context, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColor.primaryColor, Color(0xFF333333)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: AppTheme.shadowMedium(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.translate('where_to_go'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          const Text(
            'Book a professional helper for your next trip',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: AppTheme.spaceLG),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: loc.translate('instant'),
                  variant: ButtonVariant.secondary,
                  color: Colors.white,
                  textStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  onPressed: () => context.push(AppRouter.instantSearch),
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: CustomButton(
                  text: loc.translate('scheduled'),
                  variant: ButtonVariant.outlined,
                  color: Colors.white,
                  onPressed: () => context.push(AppRouter.scheduledSearch),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AppLocalizations loc) {
    final List<Map<String, dynamic>> actions = [
      {'icon': Icons.chat_outlined, 'label': loc.translate('chat'), 'route': '/chats'},
      {'icon': Icons.account_balance_wallet_outlined, 'label': loc.translate('wallet'), 'route': AppRouter.userInvoices},
      {'icon': Icons.star_outline_rounded, 'label': loc.translate('ratings'), 'route': '/ratings'},
      {'icon': Icons.help_outline_rounded, 'label': loc.translate('support'), 'route': '/support'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((action) {
        return Column(
          children: [
            InkWell(
              onTap: () => context.push(action['route']),
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spaceMD),
                decoration: BoxDecoration(
                  color: AppColor.lightSurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  boxShadow: AppTheme.shadowLight(context),
                  border: Border.all(color: AppColor.lightBorder),
                ),
                child: Icon(action['icon'], color: AppColor.primaryColor),
              ),
            ),
            const SizedBox(height: AppTheme.spaceSM),
            Text(
              action['label'],
              style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: AppColor.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppColor.lightBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.history_rounded, size: 48, color: AppColor.lightTextSecondary),
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            loc.translate('no_bookings_yet'),
            style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            'Your travel history will appear here',
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
