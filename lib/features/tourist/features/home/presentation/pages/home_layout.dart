import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toury/features/tourist/features/home/presentation/pages/tourist_home_page.dart';
import 'package:toury/features/tourist/features/profile/presentation/page/accounts_settings_page.dart';
import 'package:toury/features/tourist/features/home/presentation/pages/explore_page.dart';
import '../../../../../../core/di/injection_container.dart';
import 'package:toury/features/tourist/features/user_booking/presentation/cubits/booking_status_cubit.dart';
import 'package:toury/features/tourist/features/user_booking/presentation/cubits/my_bookings_cubit.dart';
import 'package:toury/features/tourist/features/user_booking/presentation/cubits/search_helpers_cubit.dart';
import '../../../../../../core/widgets/custom_bottom_nav_bar.dart';
import '../cubit/bottom_nav_cubit.dart';
import '../cubit/bottom_nav_state.dart';

class HomeLayout extends StatelessWidget {
  const HomeLayout({super.key});

  @override
  Widget build(BuildContext context) {

    final pages = [
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => sl<MyBookingsCubit>()..getBookings(pageSize: 5)),
          BlocProvider(create: (context) => sl<BookingStatusCubit>()..startPollingForActive()),
          BlocProvider(create: (context) => sl<SearchHelpersCubit>()),
        ],
        child: const TouristHomePage(),
      ),
      const ExplorePage(),
      const AccountSettingsPage(),
    ];

    return BlocBuilder<BottomNavCubit, BottomNavState>(
      builder: (context, state) {
        return Scaffold(
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) {
              final offsetAnimation = Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offsetAnimation, child: child),
              );
            },
            child: IndexedStack(
              key: ValueKey(state.currentIndex),
              index: state.currentIndex,
              children: pages,
            ),
          ),
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: state.currentIndex,
            onTap: (index) => context.read<BottomNavCubit>().changeTab(index),
          ),
        );
      },
    );
  }
}
