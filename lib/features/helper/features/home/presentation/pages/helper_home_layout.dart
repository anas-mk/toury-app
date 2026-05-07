import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/widgets/app_bottom_nav.dart';

class HelperHomeLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HelperHomeLayout({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
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
          ),
          AppBottomNavItem(
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet_rounded,
            label: loc.translate('wallet'),
          ),
          AppBottomNavItem(
            icon: Icons.language_outlined,
            activeIcon: Icons.language_rounded,
            label: loc.translate('language'),
          ),
          AppBottomNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: loc.translate('account'),
          ),
        ],
      ),
    );
  }
}
