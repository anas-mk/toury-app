import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/widgets/app_bottom_nav.dart';
import '../../../helper_bookings/presentation/cubit/incoming_requests_cubit.dart';

class HelperHomeLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HelperHomeLayout({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return BlocProvider.value(
      value: sl<IncomingRequestsCubit>(),
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: BlocBuilder<IncomingRequestsCubit, IncomingRequestsState>(
          builder: (context, reqState) {
            var requestCount = 0;
            if (reqState is IncomingRequestsLoaded) {
              requestCount = reqState.totalCount;
            }
            if (reqState is IncomingRequestsEmpty) {
              requestCount = 0;
            }

            return AppBottomNavBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) => navigationShell.goBranch(index),
              items: [
                AppBottomNavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: loc.translate('home'),
                ),
                AppBottomNavItem(
                  icon: Icons.assignment_outlined,
                  activeIcon: Icons.assignment_rounded,
                  label: loc.translate('bookings'),
                  badgeCount: requestCount,
                ),
                AppBottomNavItem(
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet_rounded,
                  label: loc.translate('wallet'),
                ),
                AppBottomNavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: loc.translate('account'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
